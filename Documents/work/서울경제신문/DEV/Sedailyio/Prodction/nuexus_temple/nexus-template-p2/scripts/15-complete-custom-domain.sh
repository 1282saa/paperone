#!/bin/bash

# 커스텀 도메인 설정 완료 스크립트

source "$(dirname "$0")/00-config.sh"

CUSTOM_DOMAIN="w1.sedaily.ai"
CLOUDFRONT_DISTRIBUTION_ID="E10S6CKR5TLUBG"
CERT_ARN="arn:aws:acm:us-east-1:887078546492:certificate/c25d833a-74d8-4d95-a923-0204d806ea89"

log_info "커스텀 도메인 설정 완료 중: $CUSTOM_DOMAIN"

# 인증서 상태 확인
log_info "인증서 상태 확인 중..."
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

log_info "현재 인증서 상태: $CERT_STATUS"

if [ "$CERT_STATUS" == "PENDING_VALIDATION" ]; then
    log_warning "인증서가 아직 검증 중입니다."
    log_info "DNS 레코드 전파를 기다리는 중... (최대 10분)"
    
    # 최대 10분 대기
    for i in {1..20}; do
        sleep 30
        CERT_STATUS=$(aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.Status' \
            --output text)
        
        log_info "[$i/20] 인증서 상태: $CERT_STATUS"
        
        if [ "$CERT_STATUS" == "ISSUED" ]; then
            log_success "인증서 발급 완료!"
            break
        fi
        
        if [ $i -eq 20 ]; then
            log_error "인증서 검증 시간 초과. DNS 레코드를 확인해주세요."
            log_info "수동으로 나중에 다시 실행: bash scripts/15-complete-custom-domain.sh"
            exit 1
        fi
    done
fi

if [ "$CERT_STATUS" != "ISSUED" ]; then
    log_error "인증서가 발급되지 않았습니다. 상태: $CERT_STATUS"
    exit 1
fi

log_success "인증서 발급 완료"

# CloudFront 배포 업데이트
log_info "CloudFront 배포 업데이트 중..."

# 현재 배포 설정 가져오기
aws cloudfront get-distribution-config \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --region us-east-1 > /tmp/cf-current.json

if [ $? -ne 0 ]; then
    log_error "CloudFront 배포 정보를 가져올 수 없습니다."
    exit 1
fi

# ETag 추출
ETAG=$(jq -r '.ETag' /tmp/cf-current.json)

# 배포 설정 수정
jq --arg domain "$CUSTOM_DOMAIN" --arg cert "$CERT_ARN" '
.DistributionConfig.Aliases = {
    "Quantity": 1,
    "Items": [$domain]
} |
.DistributionConfig.ViewerCertificate = {
    "ACMCertificateArn": $cert,
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021",
    "CertificateSource": "acm"
}
' /tmp/cf-current.json | jq '.DistributionConfig' > /tmp/cf-updated.json

# 배포 업데이트
log_info "CloudFront 배포 업데이트 실행 중..."
aws cloudfront update-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --distribution-config file:///tmp/cf-updated.json \
    --if-match "$ETAG" \
    --region us-east-1

if [ $? -eq 0 ]; then
    log_success "CloudFront 배포 업데이트 완료"
    
    # 결과 저장
    echo "CUSTOM_DOMAIN=$CUSTOM_DOMAIN" >> "$PROJECT_ROOT/endpoints.txt"
    echo "SSL_CERTIFICATE_ARN=$CERT_ARN" >> "$PROJECT_ROOT/endpoints.txt"
    
    log_success "커스텀 도메인 설정 완료!"
    log_info ""
    log_info "=== 다음 단계 ==="
    log_info "1. DNS CNAME 설정: $CUSTOM_DOMAIN → d9am5o27m55dc.cloudfront.net"
    log_info "2. CloudFront 배포 완료 대기 (10-15분)"
    log_info "3. https://$CUSTOM_DOMAIN 접속 테스트"
    log_info ""
    log_info "=== 배포 상태 확인 ==="
    log_info "aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query 'Distribution.Status' --output text"
    log_info ""
    log_info "=== 현재 상태 ==="
    
    # 현재 배포 상태 확인
    DIST_STATUS=$(aws cloudfront get-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --query 'Distribution.Status' \
        --output text \
        --region us-east-1)
    
    log_info "CloudFront 배포 상태: $DIST_STATUS"
    
    if [ "$DIST_STATUS" == "InProgress" ]; then
        log_warning "배포가 진행 중입니다. 완료까지 10-15분 소요됩니다."
    elif [ "$DIST_STATUS" == "Deployed" ]; then
        log_success "배포가 완료되었습니다!"
    fi
    
else
    log_error "CloudFront 배포 업데이트 실패"
    exit 1
fi

# 정리
rm -f /tmp/cf-current.json /tmp/cf-updated.json

log_info "커스텀 도메인 설정이 완료되었습니다!"