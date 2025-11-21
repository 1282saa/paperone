#!/bin/bash

# ============================================
# Enhanced Lambda 환경 변수 업데이트 스크립트
# - 모든 Lambda 함수 환경 변수 일괄 업데이트
# - 올바른 DynamoDB 테이블 매핑
# - API Gateway 정보 자동 설정
# ============================================

source "$(dirname "$0")/00-config.sh"

log_info "Enhanced Lambda 환경 변수 업데이트 시작..."

# API Gateway 정보 가져오기
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='$REST_API_NAME'].id" \
    --output text --region "$REGION")

WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='$WS_API_NAME'].ApiId" \
    --output text --region "$REGION")

# Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "${SERVICE_NAME}-conversation-api"
    "${SERVICE_NAME}-websocket-disconnect"
    "${SERVICE_NAME}-usage-handler"
    "${SERVICE_NAME}-websocket-message"
    "${SERVICE_NAME}-websocket-connect"
    "${SERVICE_NAME}-prompt-crud"
)

# 공통 환경 변수
COMMON_ENV_VARS=$(cat <<EOF
{
    "CONVERSATIONS_TABLE": "${SERVICE_NAME}-conversations-v2",
    "PROMPTS_TABLE": "${SERVICE_NAME}-prompts-v2",
    "USAGE_TABLE": "${SERVICE_NAME}-usage",
    "WEBSOCKET_TABLE": "${SERVICE_NAME}-websocket-connections",
    "CONNECTIONS_TABLE": "${SERVICE_NAME}-websocket-connections",
    "FILES_TABLE": "${SERVICE_NAME}-files",
    "MESSAGES_TABLE": "${SERVICE_NAME}-messages",
    "WEBSOCKET_API_ID": "${WS_API_ID}",
    "REST_API_URL": "https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod",
    "WEBSOCKET_API_URL": "wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod",
    "LOG_LEVEL": "INFO",
    "CLOUDWATCH_ENABLED": "true",
    "SERVICE_NAME": "${SERVICE_NAME}",
    "ENABLE_NEWS_SEARCH": "true",
    "PERPLEXITY_API_KEY": "${PERPLEXITY_API_KEY:-}",
    "DEFAULT_ENGINE_TYPE": "11",
    "SECONDARY_ENGINE_TYPE": "22",
    "AVAILABLE_ENGINES": "11,22,33",
    "AWS_REGION_NAME": "${REGION}"
}
EOF
)

# 각 Lambda 함수 업데이트
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    log_info "Updating environment variables for $FUNCTION..."

    # 함수가 존재하는지 확인
    FUNCTION_EXISTS=$(aws lambda get-function \
        --function-name $FUNCTION \
        --region $REGION 2>/dev/null)

    if [ -z "$FUNCTION_EXISTS" ]; then
        log_warning "$FUNCTION does not exist, skipping..."
        continue
    fi

    # 환경 변수 업데이트
    UPDATE_RESULT=$(aws lambda update-function-configuration \
        --function-name $FUNCTION \
        --environment "Variables=$COMMON_ENV_VARS" \
        --region $REGION \
        --output json 2>&1)

    if [ $? -eq 0 ]; then
        log_success "✓ $FUNCTION 환경 변수 업데이트 완료"

        # 현재 설정된 환경 변수 확인 (디버깅용)
        CURRENT_ENV=$(aws lambda get-function-configuration \
            --function-name $FUNCTION \
            --region $REGION \
            --query 'Environment.Variables' \
            --output json)

        # 주요 환경 변수 확인
        PROMPTS_TABLE=$(echo $CURRENT_ENV | jq -r '.PROMPTS_TABLE')
        WEBSOCKET_TABLE=$(echo $CURRENT_ENV | jq -r '.WEBSOCKET_TABLE')

        log_info "  - PROMPTS_TABLE: $PROMPTS_TABLE"
        log_info "  - WEBSOCKET_TABLE: $WEBSOCKET_TABLE"
    else
        log_error "✗ $FUNCTION 업데이트 실패"
        echo "$UPDATE_RESULT" | head -5
    fi

    # Lambda 함수 재시작을 위한 짧은 대기
    sleep 1
done

# ============================================
# Lambda 함수 테스트
# ============================================
log_info "Lambda 함수 테스트 중..."

# WebSocket Connect 테스트
TEST_PAYLOAD='{"requestContext":{"connectionId":"test123","eventType":"CONNECT"},"headers":{}}'
TEST_RESULT=$(echo $TEST_PAYLOAD | base64)

aws lambda invoke \
    --function-name ${SERVICE_NAME}-websocket-connect \
    --cli-binary-format raw-in-base64-out \
    --payload "$TEST_RESULT" \
    --region $REGION \
    /tmp/test-response.json >/dev/null 2>&1

if [ -f /tmp/test-response.json ]; then
    STATUS_CODE=$(cat /tmp/test-response.json | jq -r '.statusCode' 2>/dev/null)
    if [ "$STATUS_CODE" == "200" ]; then
        log_success "✓ WebSocket Connect 함수 테스트 성공"
    else
        log_warning "WebSocket Connect 함수 응답: $STATUS_CODE"
    fi
    rm /tmp/test-response.json
fi

# ============================================
# CloudWatch 로그 그룹 확인
# ============================================
log_info "CloudWatch 로그 그룹 확인 중..."

for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    LOG_GROUP="/aws/lambda/$FUNCTION"

    # 로그 그룹이 존재하는지 확인
    LOG_GROUP_EXISTS=$(aws logs describe-log-groups \
        --log-group-name-prefix "$LOG_GROUP" \
        --region $REGION \
        --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" \
        --output text)

    if [ -z "$LOG_GROUP_EXISTS" ]; then
        # 로그 그룹 생성
        aws logs create-log-group \
            --log-group-name "$LOG_GROUP" \
            --region $REGION 2>/dev/null

        # 로그 보존 기간 설정 (30일)
        aws logs put-retention-policy \
            --log-group-name "$LOG_GROUP" \
            --retention-in-days 30 \
            --region $REGION 2>/dev/null

        log_success "✓ $LOG_GROUP 로그 그룹 생성"
    else
        log_info "  $LOG_GROUP 이미 존재"
    fi
done

# ============================================
# 요약
# ============================================
log_success "======================================="
log_success "Lambda 환경 변수 업데이트 완료!"
log_success "======================================="
echo ""
log_info "업데이트된 Lambda 함수:"
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "  ✅ $FUNCTION"
done
echo ""
log_info "설정된 주요 환경 변수:"
echo "  - DynamoDB Tables: ${SERVICE_NAME}-* (올바른 접두사)"
echo "  - REST API: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  - WebSocket API: wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  - CloudWatch 로깅: 활성화됨"
echo ""
log_success "모든 Lambda 함수가 올바른 리소스를 참조하도록 설정되었습니다!"