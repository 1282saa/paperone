#!/bin/bash

# ============================================
# CloudWatch 로그 설정 스크립트
# ============================================

SERVICE_NAME="w1"
REGION="us-east-1"
API_ID="16ayefk5lc"
WS_API_ID="prsebeg7ub"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}CloudWatch 로그 설정 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "w1-conversation-api"
    "w1-websocket-disconnect"
    "w1-usage-handler"
    "w1-websocket-message"
    "w1-websocket-connect"
    "w1-prompt-crud"
)

# ============================================
# 1. Lambda 로그 그룹 생성
# ============================================
echo -e "${YELLOW}[1/4] Lambda 로그 그룹 생성${NC}"

for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    LOG_GROUP="/aws/lambda/${FUNCTION}"

    # 로그 그룹 생성
    aws logs create-log-group \
        --log-group-name "${LOG_GROUP}" \
        --region $REGION 2>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${LOG_GROUP} 생성 완료${NC}"
    else
        echo -e "${BLUE}  ${LOG_GROUP} 이미 존재${NC}"
    fi

    # 로그 보존 기간 설정 (30일)
    aws logs put-retention-policy \
        --log-group-name "${LOG_GROUP}" \
        --retention-in-days 30 \
        --region $REGION 2>/dev/null

    # Lambda 함수 환경변수에 로그 레벨 설정
    aws lambda update-function-configuration \
        --function-name "${FUNCTION}" \
        --environment "Variables={LOG_LEVEL=INFO,CLOUDWATCH_ENABLED=true}" \
        --region $REGION >/dev/null 2>&1
done

# ============================================
# 2. API Gateway REST API 로그 설정
# ============================================
echo -e "${YELLOW}[2/4] REST API 로그 설정${NC}"

# REST API 로그 그룹 생성
REST_LOG_GROUP="/aws/api-gateway/${SERVICE_NAME}-rest-api"
aws logs create-log-group \
    --log-group-name "${REST_LOG_GROUP}" \
    --region $REGION 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ REST API 로그 그룹 생성 완료${NC}"
else
    echo -e "${BLUE}  REST API 로그 그룹 이미 존재${NC}"
fi

# 로그 보존 기간 설정
aws logs put-retention-policy \
    --log-group-name "${REST_LOG_GROUP}" \
    --retention-in-days 30 \
    --region $REGION 2>/dev/null

# API Gateway 실행 로그 활성화
aws apigateway update-stage \
    --rest-api-id $API_ID \
    --stage-name prod \
    --patch-operations \
        op=replace,path=/accessLogSettings/destinationArn,value=arn:aws:logs:${REGION}:887078546492:log-group:${REST_LOG_GROUP} \
        op=replace,path=/accessLogSettings/format,value='$context.requestId $context.identity.sourceIp $context.requestTime "$context.httpMethod $context.routeKey $context.protocol" $context.status $context.responseLength' \
    --region $REGION 2>/dev/null

echo -e "${GREEN}✓ REST API 로그 설정 완료${NC}"

# ============================================
# 3. WebSocket API 로그 설정
# ============================================
echo -e "${YELLOW}[3/4] WebSocket API 로그 설정${NC}"

# WebSocket API 로그 그룹 생성
WS_LOG_GROUP="/aws/api-gateway/${SERVICE_NAME}-websocket-api"
aws logs create-log-group \
    --log-group-name "${WS_LOG_GROUP}" \
    --region $REGION 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ WebSocket API 로그 그룹 생성 완료${NC}"
else
    echo -e "${BLUE}  WebSocket API 로그 그룹 이미 존재${NC}"
fi

# 로그 보존 기간 설정
aws logs put-retention-policy \
    --log-group-name "${WS_LOG_GROUP}" \
    --retention-in-days 30 \
    --region $REGION 2>/dev/null

# WebSocket API 로그 설정
aws apigatewayv2 update-stage \
    --api-id $WS_API_ID \
    --stage-name prod \
    --access-log-settings \
        DestinationArn=arn:aws:logs:${REGION}:887078546492:log-group:${WS_LOG_GROUP},Format='$context.requestId $context.identity.sourceIp $context.requestTime "$context.httpMethod $context.routeKey" $context.status' \
    --region $REGION 2>/dev/null

echo -e "${GREEN}✓ WebSocket API 로그 설정 완료${NC}"

# ============================================
# 4. CloudWatch 대시보드 생성
# ============================================
echo -e "${YELLOW}[4/4] CloudWatch 대시보드 생성${NC}"

DASHBOARD_BODY=$(cat <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/Lambda", "Invocations", { "stat": "Sum", "label": "총 호출 수" } ],
                    [ ".", "Errors", { "stat": "Sum", "label": "오류 수" } ],
                    [ ".", "Duration", { "stat": "Average", "label": "평균 실행 시간" } ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "${REGION}",
                "title": "Lambda 함수 메트릭",
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "log",
            "properties": {
                "query": "SOURCE '/aws/lambda/w1-websocket-message' | fields @timestamp, @message | sort @timestamp desc | limit 20",
                "region": "${REGION}",
                "title": "최근 WebSocket 메시지",
                "queryLanguage": "cwli"
            }
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/ApiGateway", "Count", { "stat": "Sum" } ],
                    [ ".", "4XXError", { "stat": "Sum" } ],
                    [ ".", "5XXError", { "stat": "Sum" } ]
                ],
                "period": 300,
                "stat": "Sum",
                "region": "${REGION}",
                "title": "API Gateway 메트릭"
            }
        }
    ]
}
EOF
)

aws cloudwatch put-dashboard \
    --dashboard-name "${SERVICE_NAME}-dashboard" \
    --dashboard-body "$DASHBOARD_BODY" \
    --region $REGION >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ CloudWatch 대시보드 생성 완료${NC}"
else
    echo -e "${YELLOW}! CloudWatch 대시보드 업데이트 완료${NC}"
fi

# ============================================
# 5. 알람 설정 (선택사항)
# ============================================
echo -e "${YELLOW}[추가] 주요 알람 설정${NC}"

# Lambda 오류 알람
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    aws cloudwatch put-metric-alarm \
        --alarm-name "${FUNCTION}-error-alarm" \
        --alarm-description "Lambda 함수 오류 발생 시 알람" \
        --metric-name Errors \
        --namespace AWS/Lambda \
        --statistic Sum \
        --period 60 \
        --threshold 5 \
        --comparison-operator GreaterThanThreshold \
        --dimensions Name=FunctionName,Value=${FUNCTION} \
        --evaluation-periods 1 \
        --region $REGION 2>/dev/null
done

echo -e "${GREEN}✓ 오류 알람 설정 완료${NC}"

# ============================================
# 요약
# ============================================
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ CloudWatch 설정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}생성된 로그 그룹:${NC}"
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "  - /aws/lambda/${FUNCTION}"
done
echo "  - ${REST_LOG_GROUP}"
echo "  - ${WS_LOG_GROUP}"
echo ""
echo -e "${BLUE}대시보드:${NC}"
echo "  https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${SERVICE_NAME}-dashboard"
echo ""
echo -e "${BLUE}로그 보존 기간:${NC} 30일"
echo -e "${BLUE}로그 레벨:${NC} INFO"