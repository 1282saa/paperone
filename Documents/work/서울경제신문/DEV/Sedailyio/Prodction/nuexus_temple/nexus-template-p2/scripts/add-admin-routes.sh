#!/bin/bash

# ============================================
# w1 서비스 REST API 라우트 추가 스크립트
# ============================================

API_ID="16ayefk5lc"
REGION="us-east-1"
SERVICE_NAME="w1"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}REST API 라우트 추가 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 ARN
PROMPT_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-prompt-crud/invocations"
CONVERSATION_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-conversation-api/invocations"
USAGE_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-usage-handler/invocations"

# 루트 리소스 ID 가져오기
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/`].id' --output text)
echo -e "${GREEN}루트 리소스 ID: $ROOT_ID${NC}"

# CORS 설정 함수
setup_cors() {
    local RESOURCE_ID=$1
    local RESOURCE_NAME=$2

    echo -e "${BLUE}$RESOURCE_NAME에 CORS 설정 중...${NC}"

    # OPTIONS 메서드 추가
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --authorization-type NONE \
        --region $REGION >/dev/null 2>&1

    # MOCK 통합 설정
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --type MOCK \
        --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
        --region $REGION >/dev/null 2>&1

    # Method Response 설정
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin":true,
            "method.response.header.Access-Control-Allow-Headers":true,
            "method.response.header.Access-Control-Allow-Methods":true,
            "method.response.header.Access-Control-Allow-Credentials":true
        }' \
        --region $REGION >/dev/null 2>&1

    # Integration Response 설정
    aws apigateway put-integration-response \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method OPTIONS \
        --status-code 200 \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'",
            "method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-User-Id'"'"'",
            "method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,DELETE,PATCH,OPTIONS'"'"'",
            "method.response.header.Access-Control-Allow-Credentials":"'"'"'true'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}✓ $RESOURCE_NAME CORS 설정 완료${NC}"
}

# HTTP 메서드 추가 함수
add_method() {
    local RESOURCE_ID=$1
    local METHOD=$2
    local LAMBDA_ARN=$3
    local RESOURCE_NAME=$4

    echo -e "${BLUE}$RESOURCE_NAME에 $METHOD 메서드 추가 중...${NC}"

    # 메서드 추가
    aws apigateway put-method \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method $METHOD \
        --authorization-type NONE \
        --region $REGION >/dev/null 2>&1

    # Lambda 통합 설정
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method $METHOD \
        --type AWS_PROXY \
        --uri "$LAMBDA_ARN" \
        --integration-http-method POST \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}✓ $RESOURCE_NAME $METHOD 메서드 추가 완료${NC}"
}

# ============================================
# 1. /admin 리소스 생성
# ============================================
echo -e "${YELLOW}[1/5] /admin 리소스 생성${NC}"
ADMIN_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "admin" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ADMIN_ID" ]; then
    ADMIN_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin`].id' --output text)
fi

# /admin/dashboard 리소스 생성
DASHBOARD_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ADMIN_ID \
    --path-part "dashboard" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$DASHBOARD_ID" ]; then
    DASHBOARD_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin/dashboard`].id' --output text)
fi

# /admin/dashboard에 메서드 추가
add_method $DASHBOARD_ID "GET" $USAGE_LAMBDA "/admin/dashboard"
add_method $DASHBOARD_ID "PUT" $USAGE_LAMBDA "/admin/dashboard"
setup_cors $DASHBOARD_ID "/admin/dashboard"

# ============================================
# 2. /tenants 리소스 생성
# ============================================
echo -e "${YELLOW}[2/5] /tenants 리소스 생성${NC}"
TENANTS_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "tenants" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$TENANTS_ID" ]; then
    TENANTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/tenants`].id' --output text)
fi

# /tenants에 메서드 추가
add_method $TENANTS_ID "GET" $USAGE_LAMBDA "/tenants"
add_method $TENANTS_ID "PUT" $USAGE_LAMBDA "/tenants"
setup_cors $TENANTS_ID "/tenants"

# ============================================
# 3. /users 리소스 생성
# ============================================
echo -e "${YELLOW}[3/5] /users 리소스 생성${NC}"
USERS_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "users" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$USERS_ID" ]; then
    USERS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/users`].id' --output text)
fi

# /users에 메서드 추가
add_method $USERS_ID "GET" $USAGE_LAMBDA "/users"
add_method $USERS_ID "PUT" $USAGE_LAMBDA "/users"
setup_cors $USERS_ID "/users"

# ============================================
# 4. /conversations/{conversationId} 리소스 생성
# ============================================
echo -e "${YELLOW}[4/5] /conversations/{conversationId} 리소스 생성${NC}"
CONVERSATIONS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/conversations`].id' --output text)

CONVERSATION_ID_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $CONVERSATIONS_ID \
    --path-part "{conversationId}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$CONVERSATION_ID_RESOURCE" ]; then
    CONVERSATION_ID_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/conversations/{conversationId}`].id' --output text)
fi

# /conversations/{conversationId}에 메서드 추가
add_method $CONVERSATION_ID_RESOURCE "GET" $CONVERSATION_LAMBDA "/conversations/{conversationId}"
add_method $CONVERSATION_ID_RESOURCE "DELETE" $CONVERSATION_LAMBDA "/conversations/{conversationId}"
setup_cors $CONVERSATION_ID_RESOURCE "/conversations/{conversationId}"

# ============================================
# 5. API 배포
# ============================================
echo -e "${YELLOW}[5/5] API 배포${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Added admin routes $(date)" \
    --region $REGION \
    --query 'id' --output text)

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ API 라우트 추가 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}추가된 라우트:${NC}"
echo "  - GET,PUT    /admin/dashboard"
echo "  - GET,PUT    /tenants"
echo "  - GET,PUT    /users"
echo "  - GET,DELETE /conversations/{conversationId}"
echo ""
echo -e "${BLUE}API Endpoint:${NC} https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""

# Lambda 권한 추가
echo -e "${YELLOW}Lambda 권한 설정 중...${NC}"

# usage-handler Lambda에 권한 부여
for RESOURCE in "admin/dashboard" "tenants" "users"; do
    aws lambda add-permission \
        --function-name ${SERVICE_NAME}-usage-handler \
        --statement-id "apigateway-${RESOURCE//\//-}-GET" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/GET/${RESOURCE}" \
        --region $REGION >/dev/null 2>&1

    aws lambda add-permission \
        --function-name ${SERVICE_NAME}-usage-handler \
        --statement-id "apigateway-${RESOURCE//\//-}-PUT" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/PUT/${RESOURCE}" \
        --region $REGION >/dev/null 2>&1
done

# conversation-api Lambda에 권한 부여
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id "apigateway-conversation-id-GET" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/GET/conversations/*" \
    --region $REGION >/dev/null 2>&1

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id "apigateway-conversation-id-DELETE" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/DELETE/conversations/*" \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}✓ Lambda 권한 설정 완료${NC}"