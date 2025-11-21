#!/bin/bash

# 커스텀 도메인 설정 (수동 인증서 버전)

source "$(dirname "$0")/00-config.sh"

CUSTOM_DOMAIN="w1.sedaily.ai"
CLOUDFRONT_DISTRIBUTION_ID="E10S6CKR5TLUBG"

log_info "커스텀 도메인 설정 시작: $CUSTOM_DOMAIN"

# 기존 인증서 확인
log_info "기존 SSL 인증서 확인 중..."
aws acm list-certificates \
    --region us-east-1 \
    --query 'CertificateSummaryList[?DomainName==`w1.sedaily.ai` || DomainName==`*.sedaily.ai`]' \
    --output table

echo
read -p "사용할 인증서 ARN을 입력하세요 (또는 Enter로 새로 생성): " CERT_ARN

if [ -z "$CERT_ARN" ]; then
    log_info "새 SSL 인증서 요청 중..."
    
    CERT_ARN=$(aws acm request-certificate \
        --domain-name "$CUSTOM_DOMAIN" \
        --validation-method DNS \
        --region us-east-1 \
        --query 'CertificateArn' \
        --output text)
    
    if [ $? -eq 0 ]; then
        log_success "SSL 인증서 요청 완료: $CERT_ARN"
        
        log_info "DNS 검증 레코드:"
        aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
            --output table
        
        log_warning "DNS 검증을 완료한 후 스크립트를 다시 실행해주세요."
        log_info "인증서 ARN: $CERT_ARN"
        exit 0
    else
        log_error "SSL 인증서 요청 실패"
        exit 1
    fi
fi

# 인증서 상태 확인
log_info "인증서 상태 확인 중..."
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

log_info "인증서 상태: $CERT_STATUS"

if [ "$CERT_STATUS" != "ISSUED" ]; then
    log_error "인증서가 발급되지 않았습니다. DNS 검증을 완료해주세요."
    exit 1
fi

# CloudFront 배포 업데이트
log_info "CloudFront 배포 업데이트 중..."

# 현재 설정 가져오기
aws cloudfront get-distribution-config \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --region us-east-1 > /tmp/cf-current.json

ETAG=$(jq -r '.ETag' /tmp/cf-current.json)

# 설정 업데이트
jq --arg domain "$CUSTOM_DOMAIN" --arg cert "$CERT_ARN" '
.DistributionConfig |= {
    Aliases: {
        Quantity: 1,
        Items: [$domain]
    },
    ViewerCertificate: {
        ACMCertificateArn: $cert,
        SSLSupportMethod: "sni-only",
        MinimumProtocolVersion: "TLSv1.2_2021",
        CertificateSource: "acm"
    }
} + .
' /tmp/cf-current.json | jq '.DistributionConfig' > /tmp/cf-updated.json

# 배포 업데이트 실행
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
    log_info "다음 단계:"
    log_info "1. DNS 설정: $CUSTOM_DOMAIN → d9am5o27m55dc.cloudfront.net (CNAME)"
    log_info "2. 배포 완료 대기 (10-15분)"
    log_info "3. https://$CUSTOM_DOMAIN 접속 테스트"
    log_info ""
    log_info "배포 상태 확인:"
    log_info "aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --query 'Distribution.Status' --output text"
    
else
    log_error "CloudFront 배포 업데이트 실패"
    exit 1
fi

# 정리
rm -f /tmp/cf-current.json /tmp/cf-updated.json