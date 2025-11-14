#!/bin/bash

# 커스텀 도메인 설정 상태 확인

source "$(dirname "$0")/00-config.sh"

CUSTOM_DOMAIN="w1.sedaily.ai"
CLOUDFRONT_DISTRIBUTION_ID="E10S6CKR5TLUBG"
CERT_ARN="arn:aws:acm:us-east-1:887078546492:certificate/c25d833a-74d8-4d95-a923-0204d806ea89"

log_info "커스텀 도메인 설정 상태 확인"
log_info "도메인: $CUSTOM_DOMAIN"
log_info "CloudFront ID: $CLOUDFRONT_DISTRIBUTION_ID"
log_info "인증서 ARN: $CERT_ARN"
echo

# 1. 인증서 상태 확인
log_info "=== SSL 인증서 상태 ==="
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    log_info "인증서 상태: $CERT_STATUS"
    
    if [ "$CERT_STATUS" == "ISSUED" ]; then
        log_success "✅ 인증서 발급 완료"
    elif [ "$CERT_STATUS" == "PENDING_VALIDATION" ]; then
        log_warning "⏳ 인증서 검증 대기 중"
        log_info "DNS 검증 레코드 확인:"
        aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
            --output json 2>/dev/null
    else
        log_error "❌ 인증서 상태 이상: $CERT_STATUS"
    fi
else
    log_error "❌ 인증서 정보를 가져올 수 없습니다"
fi

echo

# 2. CloudFront 배포 상태 확인
log_info "=== CloudFront 배포 상태 ==="
DIST_STATUS=$(aws cloudfront get-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --query 'Distribution.Status' \
    --output text \
    --region us-east-1 2>/dev/null)

if [ $? -eq 0 ]; then
    log_info "배포 상태: $DIST_STATUS"
    
    if [ "$DIST_STATUS" == "Deployed" ]; then
        log_success "✅ 배포 완료"
    elif [ "$DIST_STATUS" == "InProgress" ]; then
        log_warning "⏳ 배포 진행 중"
    else
        log_warning "⚠️  배포 상태: $DIST_STATUS"
    fi
    
    # 현재 도메인 설정 확인
    ALIASES=$(aws cloudfront get-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query 'Distribution.DistributionConfig.Aliases.Items' \
        --output json \
        --region us-east-1 2>/dev/null)
    
    log_info "현재 설정된 도메인: $ALIASES"
else
    log_error "❌ CloudFront 배포 정보를 가져올 수 없습니다"
fi

echo

# 3. DNS 확인
log_info "=== DNS 확인 ==="
log_info "DNS 검증 레코드 확인:"
echo "nslookup _38633f378cb4b9ca8080cb36e7c6a345.w1.sedaily.ai"

echo

# 4. 다음 단계 안내
log_info "=== 다음 단계 ==="
if [ "$CERT_STATUS" == "PENDING_VALIDATION" ]; then
    log_warning "1. DNS에 검증 레코드 추가 필요:"
    log_info "   Name: _38633f378cb4b9ca8080cb36e7c6a345.w1.sedaily.ai."
    log_info "   Type: CNAME"
    log_info "   Value: _228d5c744bee29ca99f8cd1f38a8f566.xlfgrmvvlj.acm-validations.aws."
    log_info "2. DNS 전파 대기 (5-30분)"
    log_info "3. 인증서 발급 후 CloudFront 업데이트"
elif [ "$CERT_STATUS" == "ISSUED" ]; then
    log_success "1. 인증서 준비 완료"
    log_info "2. CloudFront 업데이트 실행: bash scripts/15-complete-custom-domain.sh"
    log_info "3. DNS CNAME 설정: w1.sedaily.ai → d9am5o27m55dc.cloudfront.net"
fi

echo
log_info "상태 재확인: bash scripts/check-custom-domain-status.sh"