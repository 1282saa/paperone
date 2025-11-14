#!/bin/bash

# ============================================
# Enhanced REST API Gateway 설정
# - 모든 라우트 자동 생성
# - CORS 완벽 설정
# - Lambda 통합 자동화
# ============================================

source "$(dirname "$0")/00-config.sh"

log_info "Enhanced REST API Gateway 설정 시작..."

# Lambda 함수 ARN
PROMPT_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-prompt-crud/invocations"
CONVERSATION_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-conversation-api/invocations"
USAGE_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-usage-handler/invocations"

# ============================================
# 1. REST API 생성 또는 가져오기
# ============================================
API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='$REST_API_NAME'].id" \
    --output text --region "$REGION")

if [ -z "$API_ID" ]; then
    log_info "새 REST API 생성 중..."
    API_ID=$(aws apigateway create-rest-api \
        --name "$REST_API_NAME" \
        --description "REST API for $SERVICE_NAME" \
        --region "$REGION" \
        --query 'id' --output text)
    log_success "REST API 생성 완료: $API_ID"
else
    log_info "기존 REST API 사용: $API_ID"
fi

# 루트 리소스 ID
ROOT_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --region "$REGION" \
    --query 'items[?path==`/`].id' --output text)

# ============================================
# CORS 설정 함수
# ============================================
setup_cors() {
    local RESOURCE_ID=$1
    local RESOURCE_NAME=$2

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
            "method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
            "method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'",
            "method.response.header.Access-Control-Allow-Credentials":"'"'"'true'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    log_success "  ✓ $RESOURCE_NAME CORS 설정 완료"
}

# ============================================
# HTTP 메서드 추가 함수
# ============================================
add_method() {
    local RESOURCE_ID=$1
    local METHOD=$2
    local LAMBDA_ARN=$3
    local RESOURCE_NAME=$4

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

    # Method Response 추가
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $RESOURCE_ID \
        --http-method $METHOD \
        --status-code 200 \
        --response-models '{"application/json":"Empty"}' \
        --region $REGION >/dev/null 2>&1

    log_success "  ✓ $RESOURCE_NAME $METHOD 메서드 추가 완료"
}

# ============================================
# 리소스 생성 또는 가져오기 함수
# ============================================
get_or_create_resource() {
    local PARENT_ID=$1
    local PATH_PART=$2
    local FULL_PATH=$3

    # 기존 리소스 확인
    RESOURCE_ID=$(aws apigateway get-resources \
        --rest-api-id $API_ID \
        --region $REGION \
        --query "items[?path=='$FULL_PATH'].id" \
        --output text)

    if [ -z "$RESOURCE_ID" ]; then
        # 새 리소스 생성
        RESOURCE_ID=$(aws apigateway create-resource \
            --rest-api-id $API_ID \
            --parent-id $PARENT_ID \
            --path-part "$PATH_PART" \
            --region $REGION \
            --query 'id' --output text)
        log_info "  리소스 생성: $FULL_PATH ($RESOURCE_ID)"
    else
        log_info "  기존 리소스 사용: $FULL_PATH ($RESOURCE_ID)"
    fi

    echo $RESOURCE_ID
}

# ============================================
# 2. /conversations 엔드포인트
# ============================================
log_info "Setting up /conversations endpoints..."
CONVERSATIONS_ID=$(get_or_create_resource $ROOT_ID "conversations" "/conversations")
add_method $CONVERSATIONS_ID "GET" $CONVERSATION_LAMBDA "/conversations"
add_method $CONVERSATIONS_ID "POST" $CONVERSATION_LAMBDA "/conversations"
add_method $CONVERSATIONS_ID "PUT" $CONVERSATION_LAMBDA "/conversations"
setup_cors $CONVERSATIONS_ID "/conversations"

# /conversations/{conversationId}
CONVERSATION_ID=$(get_or_create_resource $CONVERSATIONS_ID "{conversationId}" "/conversations/{conversationId}")
add_method $CONVERSATION_ID "GET" $CONVERSATION_LAMBDA "/conversations/{conversationId}"
add_method $CONVERSATION_ID "DELETE" $CONVERSATION_LAMBDA "/conversations/{conversationId}"
setup_cors $CONVERSATION_ID "/conversations/{conversationId}"

# ============================================
# 3. /prompts 엔드포인트
# ============================================
log_info "Setting up /prompts endpoints..."
PROMPTS_ID=$(get_or_create_resource $ROOT_ID "prompts" "/prompts")
add_method $PROMPTS_ID "GET" $PROMPT_LAMBDA "/prompts"
add_method $PROMPTS_ID "POST" $PROMPT_LAMBDA "/prompts"
setup_cors $PROMPTS_ID "/prompts"

# /prompts/{promptId}
PROMPT_ID=$(get_or_create_resource $PROMPTS_ID "{promptId}" "/prompts/{promptId}")
add_method $PROMPT_ID "GET" $PROMPT_LAMBDA "/prompts/{promptId}"
add_method $PROMPT_ID "POST" $PROMPT_LAMBDA "/prompts/{promptId}"
add_method $PROMPT_ID "PUT" $PROMPT_LAMBDA "/prompts/{promptId}"
setup_cors $PROMPT_ID "/prompts/{promptId}"

# /prompts/{promptId}/files
FILES_ID=$(get_or_create_resource $PROMPT_ID "files" "/prompts/{promptId}/files")
add_method $FILES_ID "GET" $PROMPT_LAMBDA "/prompts/{promptId}/files"
add_method $FILES_ID "POST" $PROMPT_LAMBDA "/prompts/{promptId}/files"
setup_cors $FILES_ID "/prompts/{promptId}/files"

# /prompts/{promptId}/files/{fileId}
FILE_ID=$(get_or_create_resource $FILES_ID "{fileId}" "/prompts/{promptId}/files/{fileId}")
add_method $FILE_ID "GET" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
add_method $FILE_ID "PUT" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
add_method $FILE_ID "DELETE" $PROMPT_LAMBDA "/prompts/{promptId}/files/{fileId}"
setup_cors $FILE_ID "/prompts/{promptId}/files/{fileId}"

# ============================================
# 4. /usage 엔드포인트
# ============================================
log_info "Setting up /usage endpoints..."
USAGE_ID=$(get_or_create_resource $ROOT_ID "usage" "/usage")
add_method $USAGE_ID "GET" $USAGE_LAMBDA "/usage"
add_method $USAGE_ID "POST" $USAGE_LAMBDA "/usage"
setup_cors $USAGE_ID "/usage"

# /usage/{userId}
USER_ID=$(get_or_create_resource $USAGE_ID "{userId}" "/usage/{userId}")

# /usage/{userId}/{engineType}
ENGINE_TYPE=$(get_or_create_resource $USER_ID "{engineType}" "/usage/{userId}/{engineType}")
add_method $ENGINE_TYPE "GET" $USAGE_LAMBDA "/usage/{userId}/{engineType}"
add_method $ENGINE_TYPE "POST" $USAGE_LAMBDA "/usage/{userId}/{engineType}"
setup_cors $ENGINE_TYPE "/usage/{userId}/{engineType}"

# ============================================
# 5. /admin 엔드포인트 (Mock)
# ============================================
log_info "Setting up /admin endpoints (Mock)..."
ADMIN_ID=$(get_or_create_resource $ROOT_ID "admin" "/admin")

# Admin 하위 리소스들
for ADMIN_PATH in "dashboard" "users" "tenants" "usage"; do
    ADMIN_RESOURCE_ID=$(get_or_create_resource $ADMIN_ID "$ADMIN_PATH" "/admin/$ADMIN_PATH")

    # Mock 통합 설정
    for METHOD in "GET" "PUT"; do
        aws apigateway put-method \
            --rest-api-id $API_ID \
            --resource-id $ADMIN_RESOURCE_ID \
            --http-method $METHOD \
            --authorization-type NONE \
            --region $REGION >/dev/null 2>&1

        aws apigateway put-integration \
            --rest-api-id $API_ID \
            --resource-id $ADMIN_RESOURCE_ID \
            --http-method $METHOD \
            --type MOCK \
            --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
            --region $REGION >/dev/null 2>&1

        aws apigateway put-integration-response \
            --rest-api-id $API_ID \
            --resource-id $ADMIN_RESOURCE_ID \
            --http-method $METHOD \
            --status-code 200 \
            --response-templates '{"application/json":"{\"message\": \"Admin endpoint - Not implemented\"}"}' \
            --region $REGION >/dev/null 2>&1

        log_success "  ✓ /admin/$ADMIN_PATH $METHOD (Mock)"
    done

    setup_cors $ADMIN_RESOURCE_ID "/admin/$ADMIN_PATH"
done

# ============================================
# 6. /transcribe 엔드포인트 (Mock)
# ============================================
log_info "Setting up /transcribe endpoint (Mock)..."
TRANSCRIBE_ID=$(get_or_create_resource $ROOT_ID "transcribe" "/transcribe")

aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method POST \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $TRANSCRIBE_ID \
    --http-method POST \
    --status-code 200 \
    --response-templates '{"application/json":"{\"message\": \"Transcribe endpoint - Not implemented\"}"}' \
    --region $REGION >/dev/null 2>&1

log_success "  ✓ /transcribe POST (Mock)"
setup_cors $TRANSCRIBE_ID "/transcribe"

# ============================================
# 7. API 배포
# ============================================
log_info "API 배포 중..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Enhanced API setup with all routes and CORS" \
    --region $REGION \
    --query 'id' --output text)

if [ $? -eq 0 ]; then
    log_success "API 배포 성공! (Deployment ID: $DEPLOYMENT_ID)"
else
    log_error "API 배포 실패"
fi

# ============================================
# 8. Lambda 권한 설정
# ============================================
log_info "Lambda 권한 설정 중..."

# prompt-crud Lambda 권한
aws lambda remove-permission \
    --function-name ${SERVICE_NAME}-prompt-crud \
    --statement-id api-gateway-invoke-prompts \
    --region $REGION 2>/dev/null

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-prompt-crud \
    --statement-id api-gateway-invoke-prompts \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region $REGION >/dev/null 2>&1

# conversation-api Lambda 권한
aws lambda remove-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id api-gateway-invoke-conversations \
    --region $REGION 2>/dev/null

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id api-gateway-invoke-conversations \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region $REGION >/dev/null 2>&1

# usage-handler Lambda 권한
aws lambda remove-permission \
    --function-name ${SERVICE_NAME}-usage-handler \
    --statement-id api-gateway-invoke-usage \
    --region $REGION 2>/dev/null

aws lambda add-permission \
    --function-name ${SERVICE_NAME}-usage-handler \
    --statement-id api-gateway-invoke-usage \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*" \
    --region $REGION >/dev/null 2>&1

log_success "Lambda 권한 설정 완료"

# ============================================
# 요약
# ============================================
log_success "======================================="
log_success "Enhanced REST API 설정 완료!"
log_success "======================================="
echo ""
log_info "API ID: $API_ID"
log_info "API Endpoint: https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""
log_info "구성된 엔드포인트:"
echo "  ✅ GET,POST,PUT     /conversations"
echo "  ✅ GET,DELETE       /conversations/{conversationId}"
echo "  ✅ GET,POST         /prompts"
echo "  ✅ GET,POST,PUT     /prompts/{promptId}"
echo "  ✅ GET,POST         /prompts/{promptId}/files"
echo "  ✅ GET,PUT,DELETE   /prompts/{promptId}/files/{fileId}"
echo "  ✅ GET,POST         /usage"
echo "  ✅ GET,POST         /usage/{userId}/{engineType}"
echo "  ✅ GET,PUT          /admin/* (Mock)"
echo "  ✅ POST             /transcribe (Mock)"
echo ""
log_success "모든 엔드포인트에 CORS 설정 완료!"

# API ID를 설정 파일에 저장
echo "REST_API_ID=$API_ID" >> "$CONFIG_FILE"
echo "REST_API_URL=https://${API_ID}.execute-api.${REGION}.amazonaws.com/prod" >> "$CONFIG_FILE"