#!/bin/bash

# ==============================================
# PHASE 2: 코드 배포 및 설정
# ==============================================
# 프론트엔드 빌드/배포, 설정 파일 업데이트
# ==============================================

set -e  # 오류 발생 시 중단

source "$(dirname "$0")/00-config.sh"

echo "======================================"
echo "PHASE 2: 코드 배포 및 설정"
echo "서비스: $SERVICE_NAME"
echo "======================================"
echo ""

# 진행 상태 파일 확인
STATUS_FILE="$PROJECT_ROOT/.deployment-status"
if [ -f "$STATUS_FILE" ]; then
    source "$STATUS_FILE"
    if [ -z "$PHASE1_COMPLETED" ]; then
        log_warning "Phase 1이 완료되지 않았습니다. Phase 1을 먼저 실행해주세요."
        read -p "계속 진행하시겠습니까? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    log_warning "Phase 1 상태 파일이 없습니다."
    read -p "계속 진행하시겠습니까? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "PHASE2_STARTED=$(date +%s)" >> "$STATUS_FILE"

# API ID 확인
if [ -f "$PROJECT_ROOT/.api-ids" ]; then
    source "$PROJECT_ROOT/.api-ids"
    log_info "API ID 로드 완료"
else
    log_warning "API ID 파일이 없습니다. Phase 1을 실행했는지 확인해주세요."
fi

# ==============================================
# 9. 프론트엔드 빌드 및 배포
# ==============================================
log_info "Step 9/13: 프론트엔드 배포"
if [ -f "./09-deploy-frontend.sh" ]; then
    ./09-deploy-frontend.sh
    echo "STEP9_FRONTEND=completed" >> "$STATUS_FILE"
else
    log_warning "프론트엔드 배포 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 10. 설정 파일 업데이트
# ==============================================
log_info "Step 10/13: 설정 파일 업데이트"
if [ -f "./10-update-config.sh" ]; then
    ./10-update-config.sh
    echo "STEP10_CONFIG=completed" >> "$STATUS_FILE"
else
    log_warning "설정 업데이트 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 11. 백엔드 설정 업데이트
# ==============================================
log_info "Step 11/13: 백엔드 설정 업데이트"
if [ -f "./11-update-backend-config.sh" ]; then
    ./11-update-backend-config.sh
    echo "STEP11_BACKEND_CONFIG=completed" >> "$STATUS_FILE"
else
    log_warning "백엔드 설정 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 12. 프론트엔드 설정 업데이트
# ==============================================
log_info "Step 12/13: 프론트엔드 설정 업데이트"
if [ -f "./12-update-frontend-config.sh" ]; then
    ./12-update-frontend-config.sh
    echo "STEP12_FRONTEND_CONFIG=completed" >> "$STATUS_FILE"
else
    log_warning "프론트엔드 설정 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 13. Lambda 환경 변수 최종 업데이트
# ==============================================
log_info "Step 13/13: Lambda 환경 변수 최종 업데이트"
if [ -f "./13-update-lambda-env.sh" ]; then
    ./13-update-lambda-env.sh
    echo "STEP13_LAMBDA_ENV=completed" >> "$STATUS_FILE"
else
    log_warning "Lambda 환경변수 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# Phase 2 검증
# ==============================================
log_info "Phase 2 검증 시작..."

# API 엔드포인트 테스트
if [ -n "$REST_API_ID" ]; then
    log_info "API 엔드포인트 테스트..."
    ENDPOINT="https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod"

    # 프롬프트 조회 테스트
    log_info "프롬프트 API 테스트: $ENDPOINT/prompts/11"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$ENDPOINT/prompts/11")
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "404" ]; then
        log_success "API 테스트 성공 (HTTP $RESPONSE)"
    else
        log_warning "API 테스트 실패 (HTTP $RESPONSE)"
    fi
fi
echo ""

# S3 버킷 확인
if [ -n "$S3_BUCKET" ]; then
    log_info "S3 버킷 상태 확인..."
    FILE_COUNT=$(aws s3 ls "s3://$S3_BUCKET" --recursive | wc -l)
    log_success "S3 버킷에 $FILE_COUNT 개 파일 업로드됨"
fi
echo ""

# CloudFront 배포 확인
if [ -f "$PROJECT_ROOT/.cloudfront-url" ]; then
    CLOUDFRONT_URL=$(cat "$PROJECT_ROOT/.cloudfront-url")
    log_info "CloudFront 배포 상태 확인..."
    DIST_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='$SERVICE_NAME frontend'].Id" --output text)
    if [ -n "$DIST_ID" ]; then
        STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" --query 'Distribution.Status' --output text)
        if [ "$STATUS" = "Deployed" ]; then
            log_success "CloudFront 배포 완료: $CLOUDFRONT_URL"
        else
            log_warning "CloudFront 배포 진행중: $STATUS"
        fi
    fi
fi
echo ""

# 완료 상태 저장
echo "PHASE2_COMPLETED=$(date +%s)" >> "$STATUS_FILE"

# ==============================================
# Phase 2 완료
# ==============================================
echo "======================================"
log_success "PHASE 2: 코드 배포 완료!"
echo "======================================"
echo ""

# 엔드포인트 정보 출력
if [ -f "$PROJECT_ROOT/endpoints.txt" ]; then
    log_info "배포된 엔드포인트:"
    cat "$PROJECT_ROOT/endpoints.txt"
    echo ""
fi

# CloudFront URL 출력
if [ -f "$PROJECT_ROOT/.cloudfront-url" ]; then
    CLOUDFRONT_URL=$(cat "$PROJECT_ROOT/.cloudfront-url")
    log_info "프론트엔드 URL: $CLOUDFRONT_URL"
    echo ""
fi

# 배포 요약
echo "======================================"
echo "배포 요약"
echo "======================================"
echo "서비스명: $SERVICE_NAME"
echo "환경: $ENVIRONMENT"
echo "리전: $REGION"
echo ""

if [ -n "$REST_API_ID" ]; then
    echo "REST API: https://$REST_API_ID.execute-api.$REGION.amazonaws.com/prod"
fi

if [ -n "$WS_API_ID" ]; then
    echo "WebSocket API: wss://$WS_API_ID.execute-api.$REGION.amazonaws.com/prod"
fi

if [ -n "$CLOUDFRONT_URL" ]; then
    echo "프론트엔드: $CLOUDFRONT_URL"
fi
echo ""

echo "다음 단계:"
echo "1. 브라우저에서 프론트엔드 접속하여 테스트"
echo "2. CloudWatch 로그 모니터링"
echo "3. 필요시 CloudFront 캐시 무효화:"
echo "   aws cloudfront create-invalidation --distribution-id $DIST_ID --paths '/*'"
echo ""

log_info "문제 발생 시 TEM1_TROUBLESHOOTING_GUIDE.md 참조"