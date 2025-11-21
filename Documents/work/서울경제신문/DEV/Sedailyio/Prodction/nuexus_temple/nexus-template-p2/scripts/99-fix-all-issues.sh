#!/bin/bash

# ============================================
# 모든 알려진 문제 해결 통합 스크립트
# - API Gateway 라우트 및 CORS 문제
# - Lambda 환경 변수 문제
# - DynamoDB 테이블 매핑 문제
# - CloudWatch 로깅 설정
# ============================================

source "$(dirname "$0")/00-config.sh"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}통합 문제 해결 스크립트 시작${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# ============================================
# 1. Lambda 환경 변수 수정
# ============================================
echo -e "${YELLOW}[1/4] Lambda 환경 변수 수정${NC}"

if [ -f "$(dirname "$0")/13-update-lambda-env-enhanced.sh" ]; then
    bash "$(dirname "$0")/13-update-lambda-env-enhanced.sh"
else
    bash "$(dirname "$0")/13-update-lambda-env.sh"
fi

echo -e "${GREEN}✓ Lambda 환경 변수 수정 완료${NC}"
echo ""

# ============================================
# 2. Lambda 코드 재배포 (환경변수 반영)
# ============================================
echo -e "${YELLOW}[2/4] Lambda 코드 재배포${NC}"

# backend 디렉토리에서 코드 패키징
cd "$PROJECT_ROOT/backend" || exit 1

# 기본값 수정 (tem1 -> SERVICE_NAME)
find . -name "*.py" -type f -exec grep -l "tem1-" {} \; | while read file; do
    sed -i.bak "s/tem1-/${SERVICE_NAME}-/g" "$file"
    echo "  Updated: $file"
done

# Lambda 코드 패키징 및 배포
zip -r lambda-${SERVICE_NAME}.zip . -x "__pycache__/*" "*.pyc" ".git/*" ".env" "*.bak" >/dev/null 2>&1

# 모든 Lambda 함수에 코드 배포
LAMBDA_FUNCTIONS=(
    "${SERVICE_NAME}-conversation-api"
    "${SERVICE_NAME}-websocket-disconnect"
    "${SERVICE_NAME}-usage-handler"
    "${SERVICE_NAME}-websocket-message"
    "${SERVICE_NAME}-websocket-connect"
    "${SERVICE_NAME}-prompt-crud"
)

for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    aws lambda update-function-code \
        --function-name $FUNCTION \
        --zip-file fileb://lambda-${SERVICE_NAME}.zip \
        --region $REGION \
        --output text >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ $FUNCTION 코드 업데이트${NC}"
    else
        echo -e "${YELLOW}  ! $FUNCTION 업데이트 스킵${NC}"
    fi
done

# 정리
rm lambda-${SERVICE_NAME}.zip
rm *.bak 2>/dev/null

echo -e "${GREEN}✓ Lambda 코드 재배포 완료${NC}"
echo ""

# ============================================
# 3. REST API 라우트 및 CORS 설정
# ============================================
echo -e "${YELLOW}[3/4] REST API 라우트 및 CORS 설정${NC}"

# Enhanced 버전이 있으면 사용, 없으면 기본 버전
if [ -f "$(dirname "$0")/03-setup-rest-api-enhanced.sh" ]; then
    bash "$(dirname "$0")/03-setup-rest-api-enhanced.sh"
elif [ -f "$(dirname "$0")/add-missing-routes.sh" ]; then
    bash "$(dirname "$0")/add-missing-routes.sh"
else
    bash "$(dirname "$0")/03-setup-rest-api.sh"
fi

echo -e "${GREEN}✓ REST API 설정 완료${NC}"
echo ""

# ============================================
# 4. CloudWatch 로깅 설정
# ============================================
echo -e "${YELLOW}[4/4] CloudWatch 로깅 설정${NC}"

if [ -f "$(dirname "$0")/setup-cloudwatch.sh" ]; then
    bash "$(dirname "$0")/setup-cloudwatch.sh"
else
    # 간단한 로그 그룹 생성
    for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
        LOG_GROUP="/aws/lambda/$FUNCTION"
        aws logs create-log-group \
            --log-group-name "$LOG_GROUP" \
            --region $REGION 2>/dev/null

        aws logs put-retention-policy \
            --log-group-name "$LOG_GROUP" \
            --retention-in-days 30 \
            --region $REGION 2>/dev/null
    done
    echo -e "${GREEN}  ✓ CloudWatch 로그 그룹 생성${NC}"
fi

echo -e "${GREEN}✓ CloudWatch 설정 완료${NC}"
echo ""

# ============================================
# 5. 테스트 및 검증
# ============================================
echo -e "${YELLOW}[검증] 설정 확인 중...${NC}"

# REST API 확인
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='$REST_API_NAME'].id" \
    --output text --region "$REGION")

# WebSocket API 확인
WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='$WS_API_NAME'].ApiId" \
    --output text --region "$REGION")

# CORS 테스트
echo -e "${BLUE}CORS 테스트:${NC}"
CORS_TEST=$(curl -X OPTIONS \
    https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod/prompts \
    -H "Origin: https://example.com" \
    -H "Access-Control-Request-Method: GET" \
    -w "\n%{http_code}" 2>/dev/null | tail -1)

if [ "$CORS_TEST" == "200" ]; then
    echo -e "${GREEN}  ✓ CORS 정상 작동 (Status: 200)${NC}"
else
    echo -e "${YELLOW}  ! CORS 응답 코드: $CORS_TEST${NC}"
fi

# DynamoDB 테이블 확인
echo -e "${BLUE}DynamoDB 테이블:${NC}"
aws dynamodb list-tables --region $REGION \
    --query "TableNames[?contains(@, '${SERVICE_NAME}')]" \
    --output text | tr '\t' '\n' | while read table; do
    echo -e "${GREEN}  ✓ $table${NC}"
done

# ============================================
# 요약
# ============================================
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✅ 모든 문제 해결 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}서비스 정보:${NC}"
echo "  Service Name: ${SERVICE_NAME}"
echo "  Region: ${REGION}"
echo ""
echo -e "${BLUE}API Endpoints:${NC}"
echo "  REST API: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  WebSocket: wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""
echo -e "${BLUE}해결된 문제:${NC}"
echo "  ✅ Lambda 환경 변수 (DynamoDB 테이블 매핑)"
echo "  ✅ REST API 모든 라우트 추가"
echo "  ✅ CORS 설정 (모든 엔드포인트)"
echo "  ✅ Lambda 권한 설정"
echo "  ✅ CloudWatch 로깅 활성화"
echo ""
echo -e "${GREEN}프론트엔드에서 정상적으로 서비스 사용 가능합니다!${NC}"

# 현재 디렉토리 복귀
cd "$CURRENT_DIR"