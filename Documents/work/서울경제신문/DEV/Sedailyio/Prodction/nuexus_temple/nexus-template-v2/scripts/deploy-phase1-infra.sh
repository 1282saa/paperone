#!/bin/bash

# ==============================================
# PHASE 1: 인프라 구축
# ==============================================
# DynamoDB, Lambda, API Gateway, S3, CloudFront 설정
# ==============================================

set -e  # 오류 발생 시 중단

source "$(dirname "$0")/00-config.sh"

echo "======================================"
echo "PHASE 1: 인프라 구축 시작"
echo "서비스: $SERVICE_NAME"
echo "======================================"
echo ""

# 진행 상태 파일
STATUS_FILE="$PROJECT_ROOT/.deployment-status"
echo "PHASE1_STARTED=$(date +%s)" > "$STATUS_FILE"

# ==============================================
# 0. 사전 체크
# ==============================================
log_info "AWS CLI 설정 확인..."
aws sts get-caller-identity --region "$REGION" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    log_error "AWS CLI가 제대로 설정되지 않았습니다."
    exit 1
fi
log_success "AWS CLI 설정 확인 완료"

# ==============================================
# 1. DynamoDB 테이블 및 GSI 생성
# ==============================================
log_info "Step 1/8: DynamoDB 테이블 설정"
if [ -f "./01-create-dynamodb.sh" ]; then
    ./01-create-dynamodb.sh
    echo "STEP1_DYNAMODB=completed" >> "$STATUS_FILE"
else
    log_warning "DynamoDB 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 2. Lambda 함수 생성
# ==============================================
log_info "Step 2/8: Lambda 함수 생성"
if [ -f "./02-create-lambda-functions.sh" ]; then
    ./02-create-lambda-functions.sh
    echo "STEP2_LAMBDA=completed" >> "$STATUS_FILE"
else
    log_warning "Lambda 생성 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 3. REST API Gateway 설정
# ==============================================
log_info "Step 3/8: REST API Gateway 설정"
if [ -f "./03-setup-rest-api-enhanced.sh" ]; then
    ./03-setup-rest-api-enhanced.sh
elif [ -f "./03-setup-rest-api.sh" ]; then
    ./03-setup-rest-api.sh
else
    log_warning "REST API 스크립트가 없습니다. 스킵..."
fi
echo "STEP3_REST_API=completed" >> "$STATUS_FILE"
echo ""

# ==============================================
# 4. WebSocket API 설정
# ==============================================
log_info "Step 4/8: WebSocket API 설정"
if [ -f "./04-setup-websocket-api.sh" ]; then
    ./04-setup-websocket-api.sh
    echo "STEP4_WEBSOCKET=completed" >> "$STATUS_FILE"
else
    log_warning "WebSocket API 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 5. Lambda 권한 설정
# ==============================================
log_info "Step 5/8: Lambda 권한 설정"
if [ -f "./05-setup-lambda-permissions.sh" ]; then
    ./05-setup-lambda-permissions.sh
    echo "STEP5_PERMISSIONS=completed" >> "$STATUS_FILE"
else
    log_warning "권한 설정 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 6. Lambda 코드 배포 (초기)
# ==============================================
log_info "Step 6/8: Lambda 코드 초기 배포"
if [ -f "./06-deploy-lambda-code.sh" ]; then
    ./06-deploy-lambda-code.sh
    echo "STEP6_LAMBDA_CODE=completed" >> "$STATUS_FILE"
else
    log_warning "Lambda 코드 배포 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 7. S3 버킷 생성 (프론트엔드용)
# ==============================================
log_info "Step 7/8: S3 버킷 설정"
if [ -f "./07-create-s3-bucket.sh" ]; then
    ./07-create-s3-bucket.sh
    echo "STEP7_S3=completed" >> "$STATUS_FILE"
else
    log_warning "S3 버킷 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# 8. CloudFront 설정
# ==============================================
log_info "Step 8/8: CloudFront 배포"
if [ -f "./08-setup-cloudfront.sh" ]; then
    ./08-setup-cloudfront.sh
    echo "STEP8_CLOUDFRONT=completed" >> "$STATUS_FILE"
else
    log_warning "CloudFront 스크립트가 없습니다. 스킵..."
fi
echo ""

# ==============================================
# Phase 1 검증
# ==============================================
log_info "Phase 1 검증 시작..."

# DynamoDB 테이블 상태 확인
log_info "DynamoDB 테이블 상태:"
for table in $TABLE_CONVERSATIONS $TABLE_PROMPTS $TABLE_FILES $TABLE_MESSAGES $TABLE_USAGE $TABLE_CONNECTIONS; do
    STATUS=$(aws dynamodb describe-table --table-name "$table" --region "$REGION" \
        --query 'Table.TableStatus' --output text 2>/dev/null || echo "NOT_FOUND")
    if [ "$STATUS" = "ACTIVE" ]; then
        echo -e "  - $table: ${GREEN}$STATUS${NC}"
    elif [ "$STATUS" = "NOT_FOUND" ]; then
        echo -e "  - $table: ${RED}$STATUS${NC}"
    else
        echo -e "  - $table: ${YELLOW}$STATUS${NC}"
    fi
done
echo ""

# Lambda 함수 상태 확인
log_info "Lambda 함수 상태:"
for func in $LAMBDA_PROMPT $LAMBDA_CONVERSATION $LAMBDA_USAGE $LAMBDA_CONNECT $LAMBDA_DISCONNECT $LAMBDA_MESSAGE; do
    STATUS=$(aws lambda get-function --function-name "$func" --region "$REGION" \
        --query 'Configuration.State' --output text 2>/dev/null || echo "NOT_FOUND")
    if [ "$STATUS" = "Active" ]; then
        echo -e "  - $func: ${GREEN}$STATUS${NC}"
    elif [ "$STATUS" = "NOT_FOUND" ]; then
        echo -e "  - $func: ${RED}$STATUS${NC}"
    else
        echo -e "  - $func: ${YELLOW}$STATUS${NC}"
    fi
done
echo ""

# 완료 상태 저장
echo "PHASE1_COMPLETED=$(date +%s)" >> "$STATUS_FILE"

# ==============================================
# Phase 1 완료
# ==============================================
echo "======================================"
log_success "PHASE 1: 인프라 구축 완료!"
echo "======================================"
echo ""

# API 정보 저장
if [ -f "$PROJECT_ROOT/.api-ids" ]; then
    log_info "생성된 API 정보:"
    cat "$PROJECT_ROOT/.api-ids"
    echo ""
fi

echo "다음 단계:"
echo "1. ./deploy-phase2-code.sh 실행하여 코드 배포"
echo "2. 또는 ./deploy-all-new.sh 실행하여 전체 자동 배포"
echo ""

log_info "상태 파일: $STATUS_FILE"