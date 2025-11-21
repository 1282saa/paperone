#!/bin/bash

# ============================================
# v2-deploy-complete.sh
# 완전한 서비스 배포 (처음부터 끝까지)
# ============================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 서비스명 받기
SERVICE_NAME=${1:-w1}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "   v2 완전 배포 시작"
echo "   서비스명: ${SERVICE_NAME}"
echo "============================================"
echo ""

# 1. 하드코딩된 값 수정
echo "=== STEP 1: 하드코딩된 값 수정 ==="
if [ -f "$SCRIPT_DIR/v2-fix-hardcoded-values.sh" ]; then
    bash "$SCRIPT_DIR/v2-fix-hardcoded-values.sh" "$SERVICE_NAME"
else
    log_warning "v2-fix-hardcoded-values.sh 스크립트를 찾을 수 없습니다. 건너뜁니다."
fi
echo ""

# 2. Lambda 코드 배포
echo "=== STEP 2: Lambda 함수 배포 ==="
if [ -f "$SCRIPT_DIR/v2-deploy-lambda.sh" ]; then
    bash "$SCRIPT_DIR/v2-deploy-lambda.sh" "$SERVICE_NAME"
else
    log_warning "v2-deploy-lambda.sh 스크립트를 찾을 수 없습니다. 건너뜁니다."
fi
echo ""

# 3. API Gateway 수정
echo "=== STEP 3: API Gateway 설정 ==="
if [ -f "$SCRIPT_DIR/v2-fix-api-gateway.sh" ]; then
    bash "$SCRIPT_DIR/v2-fix-api-gateway.sh" "$SERVICE_NAME"
else
    log_warning "v2-fix-api-gateway.sh 스크립트를 찾을 수 없습니다. 건너뜁니다."
fi
echo ""

# 4. 프론트엔드 빌드 및 배포
echo "=== STEP 4: 프론트엔드 배포 ==="
source "$SCRIPT_DIR/00-config.sh"

if [ -d "$FRONTEND_DIR" ]; then
    log_info "프론트엔드 빌드 중..."
    cd "$FRONTEND_DIR"

    # 빌드
    npm run build >/dev/null 2>&1 || {
        log_error "프론트엔드 빌드 실패"
        exit 1
    }

    # S3 업로드
    S3_BUCKET="${SERVICE_NAME}-frontend"
    if aws s3 ls "s3://${S3_BUCKET}" >/dev/null 2>&1; then
        log_info "S3에 프론트엔드 업로드 중..."
        aws s3 sync dist/ "s3://${S3_BUCKET}/" --delete
        log_success "S3 업로드 완료"

        # CloudFront 무효화
        CF_DIST_ID=$(aws cloudfront list-distributions \
            --query "DistributionList.Items[?Origins.Items[0].DomainName=='${S3_BUCKET}.s3.us-east-1.amazonaws.com'].Id" \
            --output text)

        if [ -n "$CF_DIST_ID" ]; then
            log_info "CloudFront 캐시 무효화 중..."
            aws cloudfront create-invalidation \
                --distribution-id "$CF_DIST_ID" \
                --paths "/*" >/dev/null
            log_success "CloudFront 무효화 요청 완료"
        fi
    else
        log_warning "S3 버킷을 찾을 수 없습니다: ${S3_BUCKET}"
    fi
else
    log_warning "프론트엔드 디렉토리를 찾을 수 없습니다"
fi
echo ""

# 5. 배포 검증
echo "=== STEP 5: 배포 검증 ==="

# API Gateway URL 가져오기
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='${SERVICE_NAME}-rest-api'].id" \
    --output text --region "$REGION")

if [ -n "$REST_API_ID" ]; then
    API_URL="https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
    log_success "REST API: ${API_URL}"

    # PATCH 메서드 테스트
    log_info "PATCH 메서드 테스트 중..."
    TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X OPTIONS "${API_URL}/conversations/test")

    if [ "$TEST_RESPONSE" = "200" ]; then
        log_success "CORS OPTIONS 응답 정상"
    else
        log_warning "CORS OPTIONS 응답 실패: HTTP ${TEST_RESPONSE}"
    fi
fi

# WebSocket API URL 가져오기
WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='${SERVICE_NAME}-websocket-api'].ApiEndpoint" \
    --output text --region "$REGION")

if [ -n "$WS_API_ID" ]; then
    log_success "WebSocket API: ${WS_API_ID}"
fi

# CloudFront URL
if [ -n "$CF_DIST_ID" ]; then
    CF_URL=$(aws cloudfront get-distribution \
        --id "$CF_DIST_ID" \
        --query "Distribution.DomainName" \
        --output text)
    log_success "CloudFront URL: https://${CF_URL}"
fi

echo ""
echo "============================================"
echo "   배포 완료!"
echo "============================================"
echo ""
echo "서비스 정보:"
echo "  서비스명: ${SERVICE_NAME}"
echo "  리전: ${REGION}"
echo ""
echo "엔드포인트:"
echo "  REST API: ${API_URL}"
echo "  WebSocket: ${WS_API_ID}"
echo "  CloudFront: https://${CF_URL}"
echo ""
echo "다음 단계:"
echo "1. CloudFront URL에서 서비스 테스트"
echo "2. 브라우저 캐시 지우고 새로고침 (Ctrl+Shift+R)"
echo "3. 대화 제목 수정 기능 테스트"
echo ""
log_success "모든 배포가 완료되었습니다! 🎉"