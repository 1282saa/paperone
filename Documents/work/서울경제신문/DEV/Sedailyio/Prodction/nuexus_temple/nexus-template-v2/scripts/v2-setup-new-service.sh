#!/bin/bash

# ============================================
# v2-setup-new-service.sh
# 새로운 서비스를 처음부터 설정
# DynamoDB, Lambda, API Gateway, S3, CloudFront 생성
# ============================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 서비스명 입력
if [ -z "$1" ]; then
    echo "사용법: $0 <service-name>"
    echo "예시: $0 w2"
    exit 1
fi

SERVICE_NAME=$1
REGION=${2:-us-east-1}

echo "============================================"
echo "   새 서비스 설정: ${SERVICE_NAME}"
echo "   리전: ${REGION}"
echo "============================================"
echo ""
echo "⚠️  주의: 이 스크립트는 새로운 AWS 리소스를 생성합니다."
echo "    기존 리소스와 이름이 충돌하지 않도록 주의하세요."
echo ""
read -p "계속하시겠습니까? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "설정이 취소되었습니다."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 0. 환경 준비
log_info "=== STEP 0: 환경 준비 ==="

# 백엔드 .env 파일 생성
BACKEND_ENV="$(dirname "$SCRIPT_DIR")/backend/.env"
if [ ! -f "$BACKEND_ENV" ]; then
    cat > "$BACKEND_ENV" << EOF
# Backend Configuration for ${SERVICE_NAME}
SERVICE_NAME=${SERVICE_NAME}
AWS_REGION=${REGION}
ENVIRONMENT=prod

# DynamoDB Tables
CONVERSATIONS_TABLE=${SERVICE_NAME}-conversations-v2
PROMPTS_TABLE=${SERVICE_NAME}-prompts-v2
USAGE_TABLE=${SERVICE_NAME}-usage
FILES_TABLE=${SERVICE_NAME}-files
MESSAGES_TABLE=${SERVICE_NAME}-messages
CONNECTIONS_TABLE=${SERVICE_NAME}-websocket-connections

# API Gateway
REST_API_NAME=${SERVICE_NAME}-rest-api
WEBSOCKET_API_NAME=${SERVICE_NAME}-websocket-api

# Lambda Functions
LAMBDA_CONNECT=${SERVICE_NAME}-websocket-connect
LAMBDA_DISCONNECT=${SERVICE_NAME}-websocket-disconnect
LAMBDA_MESSAGE=${SERVICE_NAME}-websocket-message
LAMBDA_CONVERSATION=${SERVICE_NAME}-conversation-api
LAMBDA_PROMPT=${SERVICE_NAME}-prompt-crud
LAMBDA_USAGE=${SERVICE_NAME}-usage-handler

# S3 Buckets
S3_BUCKET=${SERVICE_NAME}-frontend
EOF
    log_success "백엔드 .env 파일 생성 완료"
fi

# 프론트엔드 .env 파일은 나중에 API Gateway 생성 후 업데이트

# 1. 하드코딩된 값 수정
log_info "=== STEP 1: 템플릿 값 수정 ==="
if [ -f "$SCRIPT_DIR/v2-fix-hardcoded-values.sh" ]; then
    bash "$SCRIPT_DIR/v2-fix-hardcoded-values.sh" "$SERVICE_NAME"
fi

# 2. DynamoDB 테이블 생성
log_info "=== STEP 2: DynamoDB 테이블 생성 ==="
if [ -f "$SCRIPT_DIR/01-create-dynamodb.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/01-create-dynamodb.sh"
else
    log_warning "DynamoDB 생성 스크립트를 찾을 수 없습니다"
fi

# 3. Lambda 함수 생성
log_info "=== STEP 3: Lambda 함수 생성 ==="
if [ -f "$SCRIPT_DIR/02-create-lambda-functions.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/02-create-lambda-functions.sh"
else
    log_warning "Lambda 생성 스크립트를 찾을 수 없습니다"
fi

# 4. REST API 설정
log_info "=== STEP 4: REST API Gateway 설정 ==="
if [ -f "$SCRIPT_DIR/03-setup-rest-api.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/03-setup-rest-api.sh"

    # API Gateway ID 가져오기
    REST_API_ID=$(aws apigateway get-rest-apis \
        --query "items[?name=='${SERVICE_NAME}-rest-api'].id" \
        --output text --region "$REGION")

    # PATCH 메서드 추가
    if [ -n "$REST_API_ID" ] && [ -f "$SCRIPT_DIR/v2-fix-api-gateway.sh" ]; then
        log_info "PATCH/DELETE 메서드 추가 중..."
        bash "$SCRIPT_DIR/v2-fix-api-gateway.sh" "$SERVICE_NAME"
    fi
else
    log_warning "REST API 설정 스크립트를 찾을 수 없습니다"
fi

# 5. WebSocket API 설정
log_info "=== STEP 5: WebSocket API 설정 ==="
if [ -f "$SCRIPT_DIR/04-setup-websocket-api.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/04-setup-websocket-api.sh"
else
    log_warning "WebSocket API 설정 스크립트를 찾을 수 없습니다"
fi

# 6. S3 버킷 생성
log_info "=== STEP 6: S3 버킷 생성 ==="
if [ -f "$SCRIPT_DIR/07-create-s3-bucket.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/07-create-s3-bucket.sh"
else
    log_warning "S3 버킷 생성 스크립트를 찾을 수 없습니다"
fi

# 7. CloudFront 설정
log_info "=== STEP 7: CloudFront 배포 설정 ==="
if [ -f "$SCRIPT_DIR/08-setup-cloudfront.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/08-setup-cloudfront.sh"
else
    log_warning "CloudFront 설정 스크립트를 찾을 수 없습니다"
fi

# 8. Lambda 코드 배포
log_info "=== STEP 8: Lambda 코드 배포 ==="
if [ -f "$SCRIPT_DIR/v2-deploy-lambda.sh" ]; then
    bash "$SCRIPT_DIR/v2-deploy-lambda.sh" "$SERVICE_NAME"
else
    log_warning "Lambda 배포 스크립트를 찾을 수 없습니다"
fi

# 9. 프론트엔드 환경 설정 업데이트
log_info "=== STEP 9: 프론트엔드 환경 설정 ==="

# API Gateway 정보 가져오기
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='${SERVICE_NAME}-rest-api'].id" \
    --output text --region "$REGION")

WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='${SERVICE_NAME}-websocket-api'].ApiId" \
    --output text --region "$REGION")

CF_DIST_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Origins.Items[0].DomainName=='${SERVICE_NAME}-frontend.s3.${REGION}.amazonaws.com'].Id" \
    --output text)

CF_DOMAIN=$(aws cloudfront get-distribution \
    --id "$CF_DIST_ID" \
    --query "Distribution.DomainName" \
    --output text 2>/dev/null || echo "")

# 프론트엔드 .env 파일 생성
FRONTEND_ENV="$(dirname "$SCRIPT_DIR")/frontend/.env"
cat > "$FRONTEND_ENV" << EOF
# Frontend Configuration for ${SERVICE_NAME}
# Generated: $(date +"%Y-%m-%d")

# API Endpoints
VITE_API_BASE_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_WS_URL=wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_API_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_PROMPT_API_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_WEBSOCKET_URL=wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_USAGE_API_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod
VITE_CONVERSATION_API_URL=https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod

# CloudFront
VITE_CLOUDFRONT_DOMAIN=${CF_DOMAIN}

# Service Settings
VITE_SERVICE_NAME=${SERVICE_NAME}
VITE_AWS_REGION=${REGION}
VITE_USE_MOCK=false
VITE_SERVICE_TYPE=column

# Branding
VITE_APP_NAME=${SERVICE_NAME} AI Assistant
VITE_APP_DESCRIPTION=${SERVICE_NAME} AI Service

# PDF.js
VITE_PDFJS_CDN_URL=https://cdnjs.cloudflare.com/ajax/libs/pdf.js
EOF

log_success "프론트엔드 .env 파일 생성 완료"

# 10. 프론트엔드 빌드 및 배포
log_info "=== STEP 10: 프론트엔드 배포 ==="
if [ -f "$SCRIPT_DIR/09-deploy-frontend.sh" ]; then
    SERVICE_NAME="$SERVICE_NAME" bash "$SCRIPT_DIR/09-deploy-frontend.sh"
else
    log_warning "프론트엔드 배포 스크립트를 찾을 수 없습니다"
fi

# 결과 출력
echo ""
echo "============================================"
echo "   🎉 서비스 설정 완료!"
echo "============================================"
echo ""
echo "서비스 정보:"
echo "  서비스명: ${SERVICE_NAME}"
echo "  리전: ${REGION}"
echo ""
echo "엔드포인트:"
echo "  REST API: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  WebSocket: wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  CloudFront: https://${CF_DOMAIN}"
echo ""
echo "다음 단계:"
echo "1. CloudFront URL에서 서비스 접속"
echo "2. Cognito 사용자 풀 설정 (필요시)"
echo "3. 커스텀 도메인 연결 (선택사항)"
echo ""
log_success "모든 설정이 완료되었습니다!"