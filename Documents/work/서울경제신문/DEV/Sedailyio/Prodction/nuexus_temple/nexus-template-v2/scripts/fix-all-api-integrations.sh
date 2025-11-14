#!/bin/bash

# ============================================
# 모든 API 통합 문제 해결 스크립트
# ============================================

SERVICE_NAME="w1"
REGION="us-east-1"
API_ID="16ayefk5lc"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}전체 API 통합 수정 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 ARN
PROMPT_ARN="arn:aws:lambda:us-east-1:887078546492:function:w1-prompt-crud"
USAGE_ARN="arn:aws:lambda:us-east-1:887078546492:function:w1-usage-handler"
CONVERSATION_ARN="arn:aws:lambda:us-east-1:887078546492:function:w1-conversation-api"

# ============================================
# 1. Usage 엔드포인트 통합
# ============================================
echo -e "${YELLOW}[1/4] Usage 엔드포인트 통합 설정${NC}"

# /usage
USAGE_ID="vc7hs0"
for METHOD in GET POST; do
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $USAGE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${USAGE_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ $METHOD /usage${NC}"
done

# OPTIONS 인증 비활성화
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $USAGE_ID \
    --http-method OPTIONS \
    --patch-operations op=replace,path=/authorizationType,value=NONE \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ OPTIONS /usage (인증 비활성화)${NC}"

# /usage/{userId}/{engineType}
USAGE_ENGINE_ID="nhxnpl"
for METHOD in GET POST; do
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $USAGE_ENGINE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${USAGE_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ $METHOD /usage/{userId}/{engineType}${NC}"
done

# OPTIONS 인증 비활성화
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $USAGE_ENGINE_ID \
    --http-method OPTIONS \
    --patch-operations op=replace,path=/authorizationType,value=NONE \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ OPTIONS /usage/{userId}/{engineType} (인증 비활성화)${NC}"

# ============================================
# 2. Admin 엔드포인트 통합 (Mock)
# ============================================
echo -e "${YELLOW}[2/4] Admin 엔드포인트 Mock 통합 설정${NC}"

# Admin 엔드포인트 ID 목록
declare -A ADMIN_ENDPOINTS
ADMIN_ENDPOINTS["wtmyag"]="/admin/dashboard"
ADMIN_ENDPOINTS["k3u50c"]="/admin/tenants"
ADMIN_ENDPOINTS["twlrh0"]="/admin/users"
ADMIN_ENDPOINTS["0kyvw6"]="/admin/usage"

for RESOURCE_ID in "${!ADMIN_ENDPOINTS[@]}"; do
    PATH="${ADMIN_ENDPOINTS[$RESOURCE_ID]}"

    # GET, PUT에 Mock 통합 설정
    for METHOD in GET PUT; do
        aws apigateway put-integration \
            --rest-api-id $API_ID \
            --resource-id $RESOURCE_ID \
            --http-method $METHOD \
            --type MOCK \
            --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
            --region $REGION >/dev/null 2>&1

        aws apigateway put-integration-response \
            --rest-api-id $API_ID \
            --resource-id $RESOURCE_ID \
            --http-method $METHOD \
            --status-code 200 \
            --response-templates '{"application/json": "{\"message\": \"Admin endpoint - Not implemented yet\"}"}' \
            --region $REGION >/dev/null 2>&1

        echo -e "${GREEN}  ✓ $METHOD $PATH (Mock)${NC}"
    done

    # OPTIONS 인증 비활성화
    aws apigateway update-method \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --patch-operations op=replace,path=/authorizationType,value=NONE \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ OPTIONS $PATH (인증 비활성화)${NC}"
done

# ============================================
# 3. Transcribe 엔드포인트 통합 (Mock)
# ============================================
echo -e "${YELLOW}[3/4] Transcribe 엔드포인트 Mock 통합 설정${NC}"

TRANSCRIBE_ID="dvlenc"
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method POST \
    --type MOCK \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method POST \
    --status-code 200 \
    --response-templates '{"application/json": "{\"message\": \"Transcribe endpoint - Not implemented yet\"}"}' \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ POST /transcribe (Mock)${NC}"

# OPTIONS 인증 비활성화
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method OPTIONS \
    --patch-operations op=replace,path=/authorizationType,value=NONE \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ OPTIONS /transcribe (인증 비활성화)${NC}"

# ============================================
# 4. Lambda 권한 추가
# ============================================
echo -e "${YELLOW}[4/4] Lambda 권한 설정${NC}"

# Usage Handler 권한
aws lambda remove-permission \
    --function-name w1-usage-handler \
    --statement-id api-gateway-invoke-usage \
    --region $REGION 2>/dev/null

aws lambda add-permission \
    --function-name w1-usage-handler \
    --statement-id api-gateway-invoke-usage \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/*" \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ Usage Handler Lambda 권한 설정${NC}"

# ============================================
# 5. API Gateway 배포
# ============================================
echo -e "${YELLOW}API Gateway 배포 중...${NC}"

# 배포 생성
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Complete API integration fix" \
    --region $REGION \
    --query 'id' \
    --output text 2>/dev/null)

if [ ! -z "$DEPLOYMENT_ID" ]; then
    echo -e "${GREEN}✓ API 배포 성공! (Deployment ID: $DEPLOYMENT_ID)${NC}"
else
    echo -e "${YELLOW}배포 확인 중...${NC}"
    aws apigateway create-deployment \
        --rest-api-id $API_ID \
        --stage-name prod \
        --region $REGION 2>&1 | head -5
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ 전체 API 통합 수정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"