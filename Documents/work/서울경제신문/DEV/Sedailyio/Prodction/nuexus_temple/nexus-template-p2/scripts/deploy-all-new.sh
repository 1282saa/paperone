#!/bin/bash

# ==============================================
# 전체 배포 스크립트 (새 버전)
# ==============================================
# Phase 1과 Phase 2를 순차적으로 실행
# ==============================================

set -e  # 오류 발생 시 중단

# 색상 설정 (직접 정의)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "전체 배포 시작"
echo "======================================${NC}"
echo ""

# 서비스명과 리전 설정
SERVICE_NAME=${1:-tem1}
REGION=${2:-us-east-1}
ENVIRONMENT=${3:-prod}

export SERVICE_NAME
export AWS_REGION=$REGION
export ENVIRONMENT

echo "서비스명: $SERVICE_NAME"
echo "리전: $REGION"
echo "환경: $ENVIRONMENT"
echo ""

# Phase 1과 Phase 2 사이에 일시정지 옵션
PAUSE_BETWEEN_PHASES=${PAUSE_BETWEEN_PHASES:-false}

# 스크립트 디렉토리로 이동
cd "$(dirname "$0")"

# ==============================================
# Phase 1: 인프라 구축
# ==============================================
echo -e "${BLUE}======================================"
echo "Phase 1: 인프라 구축"
echo "======================================${NC}"
echo ""

if [ -f "./deploy-phase1-infra.sh" ]; then
    ./deploy-phase1-infra.sh "$SERVICE_NAME" "$REGION"
    PHASE1_RESULT=$?
else
    echo -e "${RED}[ERROR] Phase 1 스크립트를 찾을 수 없습니다.${NC}"
    exit 1
fi

if [ $PHASE1_RESULT -ne 0 ]; then
    echo -e "${RED}[ERROR] Phase 1 실패${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[SUCCESS] Phase 1 완료${NC}"
echo ""

# Phase 사이 일시정지 (옵션)
if [ "$PAUSE_BETWEEN_PHASES" = "true" ]; then
    echo -e "${YELLOW}Phase 2를 시작하려면 Enter를 누르세요...${NC}"
    read -r
fi

# ==============================================
# Phase 2: 코드 배포 및 설정
# ==============================================
echo -e "${BLUE}======================================"
echo "Phase 2: 코드 배포 및 설정"
echo "======================================${NC}"
echo ""

if [ -f "./deploy-phase2-code.sh" ]; then
    ./deploy-phase2-code.sh "$SERVICE_NAME" "$REGION"
    PHASE2_RESULT=$?
else
    echo -e "${RED}[ERROR] Phase 2 스크립트를 찾을 수 없습니다.${NC}"
    exit 1
fi

if [ $PHASE2_RESULT -ne 0 ]; then
    echo -e "${RED}[ERROR] Phase 2 실패${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}[SUCCESS] Phase 2 완료${NC}"
echo ""

# ==============================================
# 전체 배포 완료
# ==============================================
echo -e "${GREEN}======================================"
echo "전체 배포 완료!"
echo "======================================${NC}"
echo ""

# 배포 정보 표시
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -f "$PROJECT_ROOT/endpoints.txt" ]; then
    echo -e "${BLUE}배포된 엔드포인트:${NC}"
    cat "$PROJECT_ROOT/endpoints.txt"
    echo ""
fi

if [ -f "$PROJECT_ROOT/.cloudfront-url" ]; then
    CLOUDFRONT_URL=$(cat "$PROJECT_ROOT/.cloudfront-url")
    echo -e "${BLUE}프론트엔드 URL:${NC} $CLOUDFRONT_URL"
    echo ""
fi

# 배포 시간 계산
if [ -f "$PROJECT_ROOT/.deployment-status" ]; then
    source "$PROJECT_ROOT/.deployment-status"
    if [ -n "$PHASE1_STARTED" ] && [ -n "$PHASE2_COMPLETED" ]; then
        TOTAL_TIME=$((PHASE2_COMPLETED - PHASE1_STARTED))
        MINUTES=$((TOTAL_TIME / 60))
        SECONDS=$((TOTAL_TIME % 60))
        echo -e "${BLUE}총 배포 시간:${NC} ${MINUTES}분 ${SECONDS}초"
        echo ""
    fi
fi

echo "배포가 성공적으로 완료되었습니다!"
echo ""
echo "테스트 방법:"
echo "1. 브라우저에서 프론트엔드 URL 접속"
echo "2. 개발자 도구에서 네트워크 탭 확인"
echo "3. CloudWatch 로그 모니터링"
echo ""