#!/bin/bash

# ============================================
# 누락된 REST API 라우트 추가 스크립트
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
echo -e "${BLUE}누락된 REST API 라우트 추가 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 ARN
PROMPT_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-prompt-crud/invocations"
CONVERSATION_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-conversation-api/invocations"
USAGE_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-usage-handler/invocations"

# 루트 리소스 ID 가져오기
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/`].id' --output text)
echo -e "${GREEN}루트 리소스 ID: $ROOT_ID${NC}"

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
            "method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'"
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
# 1. /conversations에 PUT 메서드 추가
# ============================================
echo -e "${YELLOW}[1/8] /conversations PUT 메서드 추가${NC}"
CONVERSATIONS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/conversations`].id' --output text)
if [ -n "$CONVERSATIONS_ID" ]; then
    add_method $CONVERSATIONS_ID "PUT" $CONVERSATION_LAMBDA "/conversations"
fi

# ============================================
# 2. /prompts 리소스 확인 및 추가
# ============================================
echo -e "${YELLOW}[2/8] /prompts 리소스 설정${NC}"
PROMPTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/prompts`].id' --output text)

if [ -z "$PROMPTS_ID" ]; then
    PROMPTS_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_ID \
        --path-part "prompts" \
        --region $REGION \
        --query 'id' --output text)
    echo -e "${GREEN}  /prompts 리소스 생성: $PROMPTS_ID${NC}"
fi

add_method $PROMPTS_ID "GET" $PROMPT_LAMBDA "/prompts"
add_method $PROMPTS_ID "POST" $PROMPT_LAMBDA "/prompts"
setup_cors $PROMPTS_ID "/prompts"

# ============================================
# 3. /prompts/{promptId} 리소스 추가
# ============================================
echo -e "${YELLOW}[3/8] /prompts/{promptId} 리소스 설정${NC}"
PROMPT_ID_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PROMPTS_ID \
    --path-part "{promptId}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$PROMPT_ID_RESOURCE" ]; then
    PROMPT_ID_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/prompts/{promptId}`].id' --output text)
fi

add_method $PROMPT_ID_RESOURCE "GET" $PROMPT_LAMBDA "/prompts/{promptId}"
add_method $PROMPT_ID_RESOURCE "POST" $PROMPT_LAMBDA "/prompts/{promptId}"
add_method $PROMPT_ID_RESOURCE "PUT" $PROMPT_LAMBDA "/prompts/{promptId}"
setup_cors $PROMPT_ID_RESOURCE "/prompts/{promptId}"

# ============================================
# 4. /prompts/{promptId}/files 리소스 추가
# ============================================
echo -e "${YELLOW}[4/8] /prompts/{promptId}/files 리소스 설정${NC}"
FILES_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $PROMPT_ID_RESOURCE \
    --path-part "files" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$FILES_RESOURCE" ]; then
    FILES_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/prompts/{promptId}/files`].id' --output text)
fi

add_method $FILES_RESOURCE "GET" $PROMPT_LAMBDA "/prompts/{promptId}/files"
add_method $FILES_RESOURCE "POST" $PROMPT_LAMBDA "/prompts/{promptId}/files"
setup_cors $FILES_RESOURCE "/prompts/{promptId}/files"

# ============================================
# 5. /prompts/{promptId}/files/{fileId} 리소스 추가
# ============================================
echo -e "${YELLOW}[5/8] /prompts/{promptId}/files/{fileId} 리소스 설정${NC}"
FILE_ID_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $FILES_RESOURCE \
    --path-part "{fileId}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$FILE_ID_RESOURCE" ]; then
    FILE_ID_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/prompts/{promptId}/files/{fileId}`].id' --output text)
fi

add_method $FILE_ID_RESOURCE "GET" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
add_method $FILE_ID_RESOURCE "PUT" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
add_method $FILE_ID_RESOURCE "DELETE" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
setup_cors $FILE_ID_RESOURCE "/prompts/{promptId}/files/{fileId}"

# ============================================
# 6. /transcribe 리소스 추가
# ============================================
echo -e "${YELLOW}[6/8] /transcribe 리소스 설정${NC}"
TRANSCRIBE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_ID \
    --path-part "transcribe" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$TRANSCRIBE_ID" ]; then
    TRANSCRIBE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/transcribe`].id' --output text)
fi

add_method $TRANSCRIBE_ID "POST" $CONVERSATION_LAMBDA "/transcribe"
setup_cors $TRANSCRIBE_ID "/transcribe"

# ============================================
# 7. /usage 하위 리소스 추가
# ============================================
echo -e "${YELLOW}[7/8] /usage 하위 리소스 설정${NC}"
USAGE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage`].id' --output text)

if [ -z "$USAGE_ID" ]; then
    USAGE_ID=$(aws apigateway create-resource \
        --rest-api-id $API_ID \
        --parent-id $ROOT_ID \
        --path-part "usage" \
        --region $REGION \
        --query 'id' --output text)
fi

# /usage에 메서드 추가
add_method $USAGE_ID "GET" $USAGE_LAMBDA "/usage"
add_method $USAGE_ID "POST" $USAGE_LAMBDA "/usage"
setup_cors $USAGE_ID "/usage"

# /usage/{userId} 리소스 추가
USER_ID_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $USAGE_ID \
    --path-part "{userId}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$USER_ID_RESOURCE" ]; then
    USER_ID_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage/{userId}`].id' --output text)
fi

# /usage/{userId}/{engineType} 리소스 추가
ENGINE_TYPE_RESOURCE=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $USER_ID_RESOURCE \
    --path-part "{engineType}" \
    --region $REGION \
    --query 'id' --output text 2>/dev/null)

if [ -z "$ENGINE_TYPE_RESOURCE" ]; then
    ENGINE_TYPE_RESOURCE=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[?path==`/usage/{userId}/{engineType}`].id' --output text)
fi

add_method $ENGINE_TYPE_RESOURCE "GET" $USAGE_LAMBDA "/usage/{userId}/{engineType}"
add_method $ENGINE_TYPE_RESOURCE "POST" $USAGE_LAMBDA "/usage/{userId}/{engineType}"
setup_cors $ENGINE_TYPE_RESOURCE "/usage/{userId}/{engineType}"

# ============================================
# 8. API 배포
# ============================================
echo -e "${YELLOW}[8/8] API 배포${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Added missing routes $(date)" \
    --region $REGION \
    --query 'id' --output text)

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ 누락된 API 라우트 추가 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Lambda 권한 추가
echo -e "${YELLOW}Lambda 권한 설정 중...${NC}"

# prompt-crud Lambda 권한
for RESOURCE in "prompts" "prompts/*" "prompts/*/files" "prompts/*/files/*"; do
    for METHOD in "GET" "POST" "PUT" "DELETE"; do
        aws lambda add-permission \
            --function-name ${SERVICE_NAME}-prompt-crud \
            --statement-id "apigateway-${RESOURCE//\//-}-${METHOD}" \
            --action lambda:InvokeFunction \
            --principal apigateway.amazonaws.com \
            --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/${METHOD}/${RESOURCE}" \
            --region $REGION >/dev/null 2>&1
    done
done

# conversation-api Lambda 권한
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id "apigateway-conversations-PUT" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/PUT/conversations" \
    --region $REGION >/dev/null 2>&1

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id "apigateway-transcribe-POST" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/transcribe" \
    --region $REGION >/dev/null 2>&1

# usage-handler Lambda 권한
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-usage-handler \
    --statement-id "apigateway-usage-userid-enginetype-GET" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/GET/usage/*/*" \
    --region $REGION >/dev/null 2>&1

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-usage-handler \
    --statement-id "apigateway-usage-userid-enginetype-POST" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/usage/*/*" \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}✓ Lambda 권한 설정 완료${NC}"
echo ""
echo -e "${BLUE}추가된 라우트:${NC}"
echo "  ✅ PUT        /conversations"
echo "  ✅ GET,POST   /prompts"
echo "  ✅ GET,POST,PUT /prompts/{promptId}"
echo "  ✅ GET,POST   /prompts/{promptId}/files"
echo "  ✅ GET,PUT,DELETE /prompts/{promptId}/files/{fileId}"
echo "  ✅ POST       /transcribe"
echo "  ✅ GET,POST   /usage"
echo "  ✅ GET,POST   /usage/{userId}/{engineType}"
echo ""
echo -e "${BLUE}API Endpoint:${NC} https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"