#!/bin/bash

# ============================================
# v2-fix-hardcoded-values.sh
# 템플릿의 모든 하드코딩된 값을 서비스명에 맞게 수정
# ============================================

set -e

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 서비스명 입력 받기
SERVICE_NAME=${1:-w1}
OLD_SERVICE="tem1"

log_info "서비스명 변경 시작: ${OLD_SERVICE} → ${SERVICE_NAME}"

# 프로젝트 루트 디렉토리 찾기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

log_info "프로젝트 루트: $PROJECT_ROOT"

# 1. 00-config.sh 기본값 변경
log_info "00-config.sh 기본값 변경 중..."
if [ -f "$SCRIPT_DIR/00-config.sh" ]; then
    sed -i '' "s/SERVICE_NAME:-\${1:-${OLD_SERVICE}}/SERVICE_NAME:-\${1:-${SERVICE_NAME}}/g" "$SCRIPT_DIR/00-config.sh"
    log_success "00-config.sh 업데이트 완료"
else
    log_warning "00-config.sh 파일을 찾을 수 없습니다"
fi

# 2. 백엔드 Python 파일들의 하드코딩된 테이블명 변경
log_info "백엔드 Python 파일들의 하드코딩된 값 변경 중..."

# repository 파일들
BACKEND_DIR="$PROJECT_ROOT/backend"
if [ -d "$BACKEND_DIR" ]; then
    # 모든 Python 파일에서 tem1- 을 서비스명으로 변경
    find "$BACKEND_DIR" -type f -name "*.py" -exec grep -l "${OLD_SERVICE}-" {} \; | while read -r file; do
        sed -i '' "s/${OLD_SERVICE}-/${SERVICE_NAME}-/g" "$file"
        log_success "수정됨: $(basename "$file")"
    done
else
    log_error "백엔드 디렉토리를 찾을 수 없습니다: $BACKEND_DIR"
fi

# 3. 프론트엔드 .env 파일 수정 (있는 경우)
log_info "프론트엔드 환경 설정 확인 중..."
FRONTEND_ENV="$PROJECT_ROOT/frontend/.env"
FRONTEND_ENV_PROD="$PROJECT_ROOT/frontend/.env.production"

for env_file in "$FRONTEND_ENV" "$FRONTEND_ENV_PROD"; do
    if [ -f "$env_file" ]; then
        # API URL에서 tem1 관련 내용이 있다면 변경
        if grep -q "${OLD_SERVICE}" "$env_file"; then
            sed -i '' "s/${OLD_SERVICE}/${SERVICE_NAME}/g" "$env_file"
            log_success "수정됨: $(basename "$env_file")"
        fi
    fi
done

# 4. 백엔드 .env 파일 확인
log_info "백엔드 환경 설정 확인 중..."
BACKEND_ENV="$PROJECT_ROOT/backend/.env"
if [ -f "$BACKEND_ENV" ]; then
    # 테이블명이 tem1으로 되어있다면 변경
    sed -i '' "s/${OLD_SERVICE}-/${SERVICE_NAME}-/g" "$BACKEND_ENV"
    log_success "백엔드 .env 업데이트 완료"
fi

# 5. 하드코딩된 값 검증
log_info "=== 변경 사항 검증 ==="

# 남은 tem1 참조 확인
remaining_tem1=$(find "$PROJECT_ROOT" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.sh" \) -exec grep -l "${OLD_SERVICE}-" {} \; 2>/dev/null | wc -l)

if [ "$remaining_tem1" -gt 0 ]; then
    log_warning "아직 ${OLD_SERVICE} 참조가 남아있는 파일들:"
    find "$PROJECT_ROOT" -type f \( -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.sh" \) -exec grep -l "${OLD_SERVICE}-" {} \; 2>/dev/null
else
    log_success "모든 ${OLD_SERVICE} 참조가 ${SERVICE_NAME}으로 변경되었습니다"
fi

log_success "=== 하드코딩된 값 수정 완료 ==="
echo ""
echo "다음 단계:"
echo "1. Lambda 함수 재배포: ./v2-deploy-lambda.sh ${SERVICE_NAME}"
echo "2. 전체 서비스 배포: ./v2-deploy-complete.sh ${SERVICE_NAME}"