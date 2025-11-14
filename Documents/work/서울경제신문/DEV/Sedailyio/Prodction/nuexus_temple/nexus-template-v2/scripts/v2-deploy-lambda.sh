#!/bin/bash

# ============================================
# v2-deploy-lambda.sh
# Lambda 함수 코드 배포 (환경변수 자동 설정)
# ============================================

set -e

source "$(dirname "$0")/00-config.sh"

SERVICE_NAME=${1:-$SERVICE_NAME}

log_info "Lambda 코드 배포 시작 (서비스: ${SERVICE_NAME})..."

# Backend 디렉토리로 이동
cd "$BACKEND_DIR"

# 기존 패키지 정리
rm -rf package deployment.zip

log_info "요구사항 패키지 설치 중..."
pip install -r requirements.txt -t ./package --quiet

# 배포 패키지 생성
log_info "배포 패키지 생성 중..."
cd package
cp -r ../handlers .
cp -r ../services .
cp -r ../src .
cp -r ../lib .
cp -r ../utils .
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
zip -r ../deployment.zip . -q
cd ..

# WebSocket API ID 가져오기
WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='${SERVICE_NAME}-websocket-api'].ApiId" \
    --output text --region "$REGION")

if [ -z "$WS_API_ID" ]; then
    log_warning "WebSocket API를 찾을 수 없습니다. 환경변수 설정을 건너뜁니다."
fi

# Lambda 함수 업데이트 함수
update_lambda() {
    local function_name=$1

    log_info "$function_name 함수 코드 업데이트 중..."

    # 코드 업데이트
    aws lambda update-function-code \
        --function-name "$function_name" \
        --zip-file fileb://deployment.zip \
        --region "$REGION" >/dev/null

    # 업데이트 완료 대기
    aws lambda wait function-updated \
        --function-name "$function_name" \
        --region "$REGION" 2>/dev/null || true

    # 환경변수 업데이트 (서비스명 기반)
    aws lambda update-function-configuration \
        --function-name "$function_name" \
        --environment "Variables={
            CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-v2,
            PROMPTS_TABLE=${SERVICE_NAME}-prompts-v2,
            FILES_TABLE=${SERVICE_NAME}-files,
            MESSAGES_TABLE=${SERVICE_NAME}-messages,
            USAGE_TABLE=${SERVICE_NAME}-usage,
            CONNECTIONS_TABLE=${SERVICE_NAME}-websocket-connections,
            WEBSOCKET_TABLE=${SERVICE_NAME}-websocket-connections,
            ENABLE_NEWS_SEARCH=true,
            WEBSOCKET_API_ID=${WS_API_ID:-none}
        }" \
        --region "$REGION" >/dev/null 2>&1 || {
            log_warning "환경변수 업데이트 진행 중 (백그라운드)"
        }

    log_success "$function_name 코드 업데이트 완료"
}

# 모든 Lambda 함수 업데이트
LAMBDA_FUNCTIONS=(
    "${SERVICE_NAME}-websocket-connect"
    "${SERVICE_NAME}-websocket-disconnect"
    "${SERVICE_NAME}-websocket-message"
    "${SERVICE_NAME}-conversation-api"
    "${SERVICE_NAME}-prompt-crud"
    "${SERVICE_NAME}-usage-handler"
)

for func in "${LAMBDA_FUNCTIONS[@]}"; do
    if aws lambda get-function --function-name "$func" --region "$REGION" >/dev/null 2>&1; then
        update_lambda "$func"
    else
        log_warning "Lambda 함수를 찾을 수 없습니다: $func"
    fi
done

# 정리
rm -rf package deployment.zip

log_success "모든 Lambda 함수 코드 배포 완료!"
echo ""
echo "배포된 Lambda 함수들:"
for func in "${LAMBDA_FUNCTIONS[@]}"; do
    echo "  - $func"
done