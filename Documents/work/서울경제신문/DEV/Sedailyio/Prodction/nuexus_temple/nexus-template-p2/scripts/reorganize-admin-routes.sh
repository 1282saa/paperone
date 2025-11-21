#!/bin/bash

# ============================================
# Admin 라우트 재구성 스크립트 - Swagger 스펙 기준
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
echo -e "${BLUE}Admin 라우트 재구성 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 ARN
USAGE_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-usage-handler/invocations"

# 루트 리소스 ID 가져오기
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/`].id' --output text)
echo -e "${GREEN}루트 리소스 ID: $ROOT_ID${NC}"

# 기존 /admin 리소스 확인
ADMIN_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin`].id' --output text)
if [ -z "$ADMIN_ID" ]; then
    echo -e "${YELLOW}/admin 리소스 생성 중...${NC}"
    ADMIN_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_ID \
        --path-part "admin" \
        --region $REGION \
        --query 'id' --output text)
fi
echo -e "${GREEN}/admin 리소스 ID: $ADMIN_ID${NC}"

# CORS 설정 함수
setup_cors() {
    local RESOURCE_ID=$1
    local RESOURCE_NAME=$2

    echo -e "${BLUE}  $RESOURCE_NAME에 CORS 설정 중...${NC}"

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
            "method.response.header.Access-Control-Allow-Methods":true
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
            "method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
            "method.response.header.Access-Control-Allow-Methods":"'"'"'GET,PUT,OPTIONS'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}  ✓ $RESOURCE_NAME CORS 설정 완료${NC}"
}

# HTTP 메서드 추가 함수
add_method() {
    local RESOURCE_ID=$1
    local METHOD=$2
    local LAMBDA_ARN=$3
    local RESOURCE_NAME=$4

    echo -e "${BLUE}  $RESOURCE_NAME에 $METHOD 메서드 추가 중...${NC}"

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

    echo -e "${GREEN}  ✓ $RESOURCE_NAME $METHOD 메서드 추가 완료${NC}"
}

# ============================================
# 1. /admin/tenants 리소스 생성
# ============================================
echo -e "${YELLOW}[1/5] /admin/tenants 리소스 설정${NC}"
ADMIN_TENANTS_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ADMIN_ID \
    --path-part "tenants" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ADMIN_TENANTS_ID" ]; then
    ADMIN_TENANTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin/tenants`].id' --output text)
fi

add_method $ADMIN_TENANTS_ID "GET" $USAGE_LAMBDA "/admin/tenants"
add_method $ADMIN_TENANTS_ID "PUT" $USAGE_LAMBDA "/admin/tenants"
setup_cors $ADMIN_TENANTS_ID "/admin/tenants"

# ============================================
# 2. /admin/usage 리소스 생성
# ============================================
echo -e "${YELLOW}[2/5] /admin/usage 리소스 설정${NC}"
ADMIN_USAGE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ADMIN_ID \
    --path-part "usage" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ADMIN_USAGE_ID" ]; then
    ADMIN_USAGE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin/usage`].id' --output text)
fi

add_method $ADMIN_USAGE_ID "GET" $USAGE_LAMBDA "/admin/usage"
add_method $ADMIN_USAGE_ID "PUT" $USAGE_LAMBDA "/admin/usage"
setup_cors $ADMIN_USAGE_ID "/admin/usage"

# ============================================
# 3. /admin/users 리소스 생성
# ============================================
echo -e "${YELLOW}[3/5] /admin/users 리소스 설정${NC}"
ADMIN_USERS_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ADMIN_ID \
    --path-part "users" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ADMIN_USERS_ID" ]; then
    ADMIN_USERS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/admin/users`].id' --output text)
fi

add_method $ADMIN_USERS_ID "GET" $USAGE_LAMBDA "/admin/users"
add_method $ADMIN_USERS_ID "PUT" $USAGE_LAMBDA "/admin/users"
setup_cors $ADMIN_USERS_ID "/admin/users"

# ============================================
# 4. 루트 레벨 /tenants, /users 삭제
# ============================================
echo -e "${YELLOW}[4/5] 잘못된 라우트 정리${NC}"

# /tenants 삭제
TENANTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/tenants`].id' --output text)
if [ -n "$TENANTS_ID" ]; then
    echo -e "${BLUE}  /tenants 리소스 삭제 중...${NC}"
    aws apigateway delete-resource \
        --rest-api-id $API_ID \
        --resource-id $TENANTS_ID \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ /tenants 삭제 완료${NC}"
fi

# /users 삭제
USERS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/users`].id' --output text)
if [ -n "$USERS_ID" ]; then
    echo -e "${BLUE}  /users 리소스 삭제 중...${NC}"
    aws apigateway delete-resource \
        --rest-api-id $API_ID \
        --resource-id $USERS_ID \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ /users 삭제 완료${NC}"
fi

# ============================================
# 5. Lambda 권한 설정
# ============================================
echo -e "${YELLOW}[5/5] Lambda 권한 설정${NC}"

for RESOURCE in "admin/dashboard" "admin/tenants" "admin/usage" "admin/users"; do
    for METHOD in "GET" "PUT"; do
        aws lambda add-permission \
            --function-name ${SERVICE_NAME}-usage-handler \
            --statement-id "apigateway-${RESOURCE//\//-}-${METHOD}-v2" \
            --action lambda:InvokeFunction \
            --principal apigateway.amazonaws.com \
            --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${METHOD}/${RESOURCE}" \
            --region $REGION >/dev/null 2>&1
    done
done

echo -e "${GREEN}✓ Lambda 권한 설정 완료${NC}"

# ============================================
# API 배포
# ============================================
echo -e "${YELLOW}API 배포 중...${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Reorganized admin routes as per Swagger spec $(date)" \
    --region $REGION \
    --query 'id' --output text)

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Admin 라우트 재구성 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}최종 Admin 라우트 구조:${NC}"
echo "  /admin/dashboard - GET, PUT, OPTIONS"
echo "  /admin/tenants   - GET, PUT, OPTIONS"
echo "  /admin/usage     - GET, PUT, OPTIONS"
echo "  /admin/users     - GET, PUT, OPTIONS"
echo ""
echo -e "${BLUE}API Endpoint:${NC} https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo -e "${BLUE}Deployment ID:${NC} $DEPLOYMENT_ID"