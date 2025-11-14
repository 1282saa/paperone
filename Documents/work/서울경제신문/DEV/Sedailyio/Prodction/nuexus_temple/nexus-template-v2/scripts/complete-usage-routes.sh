#!/bin/bash

# ============================================
# /usage 하위 라우트 완성 스크립트
# ============================================

API_ID="16ayefk5lc"
REGION="us-east-1"
SERVICE_NAME="w1"
ACCOUNT_ID="887078546492"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}/usage 하위 라우트 설정 완료${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 ARN
USAGE_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-usage-handler/invocations"

# 루트 리소스 ID 가져오기
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/`].id' --output text)
USAGE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage`].id' --output text)

echo -e "${GREEN}Usage 리소스 ID: $USAGE_ID${NC}"

# /usage/{userId} 리소스 생성 또는 확인
echo -e "${YELLOW}[1/3] /usage/{userId} 리소스 생성${NC}"
USER_ID_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $USAGE_ID \
    --path-part "{userId}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$USER_ID_RESOURCE" ] || [ "$USER_ID_RESOURCE" == "None" ]; then
    USER_ID_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage/{userId}`].id' --output text)
    echo -e "${BLUE}/usage/{userId} 리소스가 이미 존재: $USER_ID_RESOURCE${NC}"
else
    echo -e "${GREEN}/usage/{userId} 리소스 생성 완료: $USER_ID_RESOURCE${NC}"
fi

# /usage/{userId}/{engineType} 리소스 생성
echo -e "${YELLOW}[2/3] /usage/{userId}/{engineType} 리소스 생성${NC}"
ENGINE_TYPE_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $USER_ID_RESOURCE \
    --path-part "{engineType}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ENGINE_TYPE_RESOURCE" ] || [ "$ENGINE_TYPE_RESOURCE" == "None" ]; then
    ENGINE_TYPE_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage/{userId}/{engineType}`].id' --output text)
    echo -e "${BLUE}/usage/{userId}/{engineType} 리소스가 이미 존재: $ENGINE_TYPE_RESOURCE${NC}"
else
    echo -e "${GREEN}/usage/{userId}/{engineType} 리소스 생성 완료: $ENGINE_TYPE_RESOURCE${NC}"
fi

# /usage/{userId}/{engineType}에 메서드 추가
echo -e "${YELLOW}[3/3] /usage/{userId}/{engineType} 메서드 추가${NC}"

# GET 메서드 추가
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method GET \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method GET \
    --type AWS_PROXY \
    --uri "$USAGE_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}✓ GET 메서드 추가 완료${NC}"

# POST 메서드 추가
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method POST \
    --type AWS_PROXY \
    --uri "$USAGE_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}✓ POST 메서드 추가 완료${NC}"

# OPTIONS 메서드 추가 (CORS)
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin":true,
        "method.response.header.Access-Control-Allow-Headers":true,
        "method.response.header.Access-Control-Allow-Methods":true
    }' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $ENGINE_TYPE_RESOURCE \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'",
        "method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
        "method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,OPTIONS'"'"'"
    }' \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}✓ OPTIONS 메서드 추가 완료${NC}"

# API 배포
echo -e "${YELLOW}API 배포 중...${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Completed usage routes $(date)" \
    --region $REGION \
    --query 'id' --output text)

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ /usage 하위 라우트 설정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}완성된 라우트 구조:${NC}"
echo "  /usage"
echo "    └── GET, POST, OPTIONS"
echo "  /usage/{userId}/{engineType}"
echo "    └── GET, POST, OPTIONS"
echo ""
echo -e "${BLUE}Deployment ID:${NC} $DEPLOYMENT_ID"