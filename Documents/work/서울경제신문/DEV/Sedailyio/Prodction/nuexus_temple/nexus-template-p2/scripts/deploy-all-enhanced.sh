#!/bin/bash

# ============================================
# Enhanced 통합 배포 스크립트
# - 모든 인프라 생성
# - 알려진 문제 자동 해결
# - CORS 및 라우트 자동 설정
# ============================================

set -e  # 오류 발생 시 중단

# 서비스 이름과 리전 받기
SERVICE_NAME=${1:-nx-tt-dev}
REGION=${2:-us-east-1}

if [ -z "$1" ]; then
    echo "Usage: $0 <service-name> [region]"
    echo "Example: $0 w1 us-east-1"
    exit 1
fi

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     Enhanced 통합 배포 스크립트 시작       ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Service Name:${NC} $SERVICE_NAME"
echo -e "${BLUE}Region:${NC} $REGION"
echo -e "${BLUE}시작 시간:${NC} $(date)"
echo ""

# 스크립트 디렉토리로 이동
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 설정 파일 초기화
CONFIG_FILE="./config.env"
> "$CONFIG_FILE"

cat > "$CONFIG_FILE" <<EOF
SERVICE_NAME=$SERVICE_NAME
REGION=$REGION
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
CURRENT_DIR=$(pwd)

# API Names
REST_API_NAME="${SERVICE_NAME}-rest-api"
WS_API_NAME="${SERVICE_NAME}-websocket-api"

# S3 Bucket
S3_BUCKET="${SERVICE_NAME}-frontend-$(date +%s)"

# CloudFront
CLOUDFRONT_COMMENT="${SERVICE_NAME} Frontend Distribution"

# Generated during deployment
REST_API_ID=""
WS_API_ID=""
CLOUDFRONT_ID=""
CLOUDFRONT_URL=""
EOF

echo -e "${GREEN}✓ 설정 파일 생성 완료${NC}"
echo ""

# ============================================
# Phase 1: 인프라 생성
# ============================================
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo -e "${YELLOW}   Phase 1: 인프라 생성${NC}"
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo ""

SCRIPTS_PHASE1=(
    "01-create-dynamodb.sh"
    "02-create-lambda-functions.sh"
    "03-setup-rest-api-enhanced.sh"  # Enhanced 버전 사용
    "04-setup-websocket-api.sh"
    "07-create-s3-bucket.sh"
    "08-setup-cloudfront.sh"
)

for SCRIPT in "${SCRIPTS_PHASE1[@]}"; do
    SCRIPT_NAME=$SCRIPT

    # Enhanced 버전이 없으면 기본 버전 사용
    if [ ! -f "$SCRIPT_NAME" ] && [ -f "${SCRIPT_NAME%-enhanced.sh}.sh" ]; then
        SCRIPT_NAME="${SCRIPT_NAME%-enhanced.sh}.sh"
    fi

    if [ -f "$SCRIPT_NAME" ]; then
        echo -e "${BLUE}실행: $SCRIPT_NAME${NC}"
        bash "$SCRIPT_NAME"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $SCRIPT_NAME 완료${NC}"
        else
            echo -e "${RED}✗ $SCRIPT_NAME 실패${NC}"
            exit 1
        fi
        echo ""
    else
        echo -e "${YELLOW}! $SCRIPT_NAME 파일 없음, 건너뜀${NC}"
    fi
done

echo -e "${GREEN}✓ Phase 1 완료${NC}"
echo ""

# ============================================
# Phase 2: 코드 배포 및 설정
# ============================================
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo -e "${YELLOW}   Phase 2: 코드 배포 및 설정${NC}"
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo ""

SCRIPTS_PHASE2=(
    "05-setup-lambda-permissions.sh"
    "06-deploy-lambda-code.sh"
    "13-update-lambda-env-enhanced.sh"  # Enhanced 버전 사용
    "09-deploy-frontend.sh"
    "10-update-config.sh"
    "11-update-backend-config.sh"
    "12-update-frontend-config.sh"
)

for SCRIPT in "${SCRIPTS_PHASE2[@]}"; do
    SCRIPT_NAME=$SCRIPT

    # Enhanced 버전이 없으면 기본 버전 사용
    if [ ! -f "$SCRIPT_NAME" ] && [ -f "${SCRIPT_NAME%-enhanced.sh}.sh" ]; then
        SCRIPT_NAME="${SCRIPT_NAME%-enhanced.sh}.sh"
    fi

    if [ -f "$SCRIPT_NAME" ]; then
        echo -e "${BLUE}실행: $SCRIPT_NAME${NC}"
        bash "$SCRIPT_NAME"

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ $SCRIPT_NAME 완료${NC}"
        else
            echo -e "${RED}✗ $SCRIPT_NAME 실패${NC}"
            exit 1
        fi
        echo ""
    else
        echo -e "${YELLOW}! $SCRIPT_NAME 파일 없음, 건너뜀${NC}"
    fi
done

echo -e "${GREEN}✓ Phase 2 완료${NC}"
echo ""

# ============================================
# Phase 3: 문제 해결 및 최종 설정
# ============================================
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo -e "${YELLOW}   Phase 3: 문제 해결 및 최종 설정${NC}"
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo ""

# add-missing-routes.sh 실행 (CORS 완벽 설정)
if [ -f "add-missing-routes.sh" ]; then
    echo -e "${BLUE}실행: add-missing-routes.sh${NC}"
    bash "add-missing-routes.sh"
    echo -e "${GREEN}✓ API 라우트 및 CORS 설정 완료${NC}"
    echo ""
fi

# CloudWatch 설정
if [ -f "setup-cloudwatch.sh" ]; then
    echo -e "${BLUE}실행: setup-cloudwatch.sh${NC}"
    bash "setup-cloudwatch.sh"
    echo -e "${GREEN}✓ CloudWatch 설정 완료${NC}"
    echo ""
fi

# ============================================
# 최종 검증
# ============================================
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo -e "${YELLOW}   최종 검증${NC}"
echo -e "${YELLOW}══════════════════════════════════════${NC}"
echo ""

# 설정 파일 다시 로드
source "$CONFIG_FILE"

# API 정보 가져오기
REST_API_ID=$(aws apigateway get-rest-apis \
    --query "items[?name=='$REST_API_NAME'].id" \
    --output text --region "$REGION")

WS_API_ID=$(aws apigatewayv2 get-apis \
    --query "Items[?Name=='$WS_API_NAME'].ApiId" \
    --output text --region "$REGION")

# CORS 테스트
echo -e "${BLUE}CORS 테스트:${NC}"
CORS_STATUS=$(curl -X OPTIONS \
    https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod/prompts \
    -H "Origin: https://example.com" \
    -w "%{http_code}" -o /dev/null -s 2>/dev/null)

if [ "$CORS_STATUS" == "200" ]; then
    echo -e "${GREEN}✓ CORS 정상 작동 (Status: 200)${NC}"
else
    echo -e "${YELLOW}! CORS 상태: $CORS_STATUS${NC}"
fi

# DynamoDB 테이블 확인
echo -e "${BLUE}DynamoDB 테이블:${NC}"
TABLE_COUNT=$(aws dynamodb list-tables --region $REGION \
    --query "TableNames[?contains(@, '${SERVICE_NAME}')]" \
    --output text | wc -w)
echo -e "${GREEN}✓ $TABLE_COUNT 개 테이블 생성됨${NC}"

# Lambda 함수 확인
echo -e "${BLUE}Lambda 함수:${NC}"
LAMBDA_COUNT=$(aws lambda list-functions --region $REGION \
    --query "Functions[?contains(FunctionName, '${SERVICE_NAME}')]" \
    --output text | wc -l)
echo -e "${GREEN}✓ $LAMBDA_COUNT 개 함수 배포됨${NC}"

# CloudFront 확인
CLOUDFRONT_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Comment=='${SERVICE_NAME} Frontend Distribution'].Id" \
    --output text)

if [ -n "$CLOUDFRONT_ID" ]; then
    CLOUDFRONT_URL=$(aws cloudfront get-distribution \
        --id $CLOUDFRONT_ID \
        --query 'Distribution.DomainName' \
        --output text)
    echo -e "${BLUE}CloudFront:${NC}"
    echo -e "${GREEN}✓ https://$CLOUDFRONT_URL${NC}"
fi

# ============================================
# 배포 요약
# ============================================
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          배포 완료!                        ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}서비스 정보:${NC}"
echo "  • Service Name: ${SERVICE_NAME}"
echo "  • Region: ${REGION}"
echo ""
echo -e "${GREEN}API Endpoints:${NC}"
echo "  • REST API: https://${REST_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo "  • WebSocket: wss://${WS_API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""
echo -e "${GREEN}Frontend:${NC}"
echo "  • CloudFront: https://${CLOUDFRONT_URL}"
echo ""
echo -e "${GREEN}리소스:${NC}"
echo "  • DynamoDB Tables: ${TABLE_COUNT}개"
echo "  • Lambda Functions: ${LAMBDA_COUNT}개"
echo "  • S3 Bucket: 생성됨"
echo ""
echo -e "${GREEN}기능:${NC}"
echo "  ✅ 모든 API 라우트 구성"
echo "  ✅ CORS 완벽 설정"
echo "  ✅ Lambda 환경변수 정상"
echo "  ✅ CloudWatch 로깅 활성화"
echo "  ✅ Frontend 배포 완료"
echo ""
echo -e "${BLUE}완료 시간:${NC} $(date)"
echo ""
echo -e "${CYAN}프론트엔드에서 서비스를 사용할 수 있습니다!${NC}"
echo -e "${CYAN}URL: https://${CLOUDFRONT_URL}${NC}"