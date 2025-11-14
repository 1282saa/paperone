#!/bin/bash

# ============================================
# v2-fix-api-gateway.sh
# API Gateway의 Lambda 통합 설정 수정
# PATCH, DELETE 메서드 추가 및 올바른 Lambda 연결
# ============================================

set -e

source "$(dirname "$0")/00-config.sh"

SERVICE_NAME=${1:-$SERVICE_NAME}

log_info "API Gateway 설정 수정 시작 (서비스: ${SERVICE_NAME})..."

# REST API ID 가져오기
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='${SERVICE_NAME}-rest-api'].id" \
    --output text --region "$REGION")

if [ -z "$REST_API_ID" ]; then
    log_error "REST API를 찾을 수 없습니다: ${SERVICE_NAME}-rest-api"
    exit 1
fi

log_info "REST API ID: $REST_API_ID"

# Lambda ARN
LAMBDA_ARN="arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-conversation-api"

# /conversations/{conversationId} 리소스 ID 찾기
CONVERSATION_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$REST_API_ID" \
    --query "items[?path=='/conversations/{conversationId}'].id" \
    --output text --region "$REGION")

if [ -z "$CONVERSATION_RESOURCE_ID" ]; then
    log_error "/conversations/{conversationId} 리소스를 찾을 수 없습니다"
    exit 1
fi

log_info "Conversation Resource ID: $CONVERSATION_RESOURCE_ID"

# PATCH 메서드 설정
setup_method() {
    local method=$1
    log_info "${method} 메서드 설정 중..."

    # 메서드가 이미 있는지 확인
    if aws apigateway get-method \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method "$method" \
        --region "$REGION" >/dev/null 2>&1; then
        log_info "${method} 메서드가 이미 존재합니다. 업데이트 중..."
    else
        # 메서드 생성
        aws apigateway put-method \
            --rest-api-id "$REST_API_ID" \
            --resource-id "$CONVERSATION_RESOURCE_ID" \
            --http-method "$method" \
            --authorization-type NONE \
            --region "$REGION" >/dev/null
    fi

    # 메서드 응답 설정
    aws apigateway put-method-response \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method "$method" \
        --status-code 200 \
        --response-models '{"application/json":"Empty"}' \
        --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false,"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false}' \
        --region "$REGION" >/dev/null 2>&1 || true

    # Lambda 통합 설정 (올바른 Lambda 함수로)
    aws apigateway put-integration \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method "$method" \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --region "$REGION" >/dev/null

    # 통합 응답 설정
    aws apigateway put-integration-response \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method "$method" \
        --status-code 200 \
        --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,PATCH,DELETE,OPTIONS'"'"'"}' \
        --region "$REGION" >/dev/null 2>&1 || true

    # Lambda 권한 추가
    aws lambda add-permission \
        --function-name "${SERVICE_NAME}-conversation-api" \
        --statement-id "api-gateway-${method,,}-${CONVERSATION_RESOURCE_ID}" \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${REST_API_ID}/*/${method}/conversations/{conversationId}" \
        --region "$REGION" >/dev/null 2>&1 || true

    log_success "${method} 메서드 설정 완료"
}

# PATCH와 DELETE 메서드 설정
setup_method "PATCH"
setup_method "DELETE"

# 다른 메서드들도 올바른 Lambda를 가리키는지 확인
for method in GET POST PUT; do
    if aws apigateway get-method \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method "$method" \
        --region "$REGION" >/dev/null 2>&1; then

        # 현재 통합 URI 확인
        current_uri=$(aws apigateway get-integration \
            --rest-api-id "$REST_API_ID" \
            --resource-id "$CONVERSATION_RESOURCE_ID" \
            --http-method "$method" \
            --query "uri" \
            --output text \
            --region "$REGION")

        # tem1이 포함되어 있으면 수정
        if echo "$current_uri" | grep -q "tem1"; then
            log_warning "${method} 메서드가 잘못된 Lambda를 가리키고 있습니다. 수정 중..."
            setup_method "$method"
        else
            log_success "${method} 메서드가 올바른 Lambda를 가리키고 있습니다"
        fi
    fi
done

# OPTIONS 메서드 CORS 설정
log_info "OPTIONS 메서드 CORS 설정 중..."
if ! aws apigateway get-method \
    --rest-api-id "$REST_API_ID" \
    --resource-id "$CONVERSATION_RESOURCE_ID" \
    --http-method OPTIONS \
    --region "$REGION" >/dev/null 2>&1; then

    aws apigateway put-method \
        --rest-api-id "$REST_API_ID" \
        --resource-id "$CONVERSATION_RESOURCE_ID" \
        --http-method OPTIONS \
        --authorization-type NONE \
        --region "$REGION" >/dev/null
fi

aws apigateway put-integration \
    --rest-api-id "$REST_API_ID" \
    --resource-id "$CONVERSATION_RESOURCE_ID" \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\":200}"}' \
    --region "$REGION" >/dev/null 2>&1 || true

aws apigateway put-integration-response \
    --rest-api-id "$REST_API_ID" \
    --resource-id "$CONVERSATION_RESOURCE_ID" \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,PATCH,DELETE,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
    --region "$REGION" >/dev/null 2>&1 || true

# API 배포
log_info "API Gateway 변경 사항 배포 중..."
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id "$REST_API_ID" \
    --stage-name prod \
    --region "$REGION" \
    --query "id" \
    --output text)

log_success "API Gateway 배포 완료! (Deployment ID: $DEPLOYMENT_ID)"
echo ""
echo "API Endpoint: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""
echo "설정된 메서드들:"
echo "  - GET /conversations/{conversationId}"
echo "  - POST /conversations/{conversationId}"
echo "  - PUT /conversations/{conversationId}"
echo "  - PATCH /conversations/{conversationId} ✨ NEW"
echo "  - DELETE /conversations/{conversationId} ✨ NEW"
echo "  - OPTIONS /conversations/{conversationId}"