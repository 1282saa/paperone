#!/bin/bash

# 커스텀 도메인 설정 스크립트

source "$(dirname "$0")/00-config.sh"

CUSTOM_DOMAIN="w1.sedaily.ai"
CLOUDFRONT_DISTRIBUTION_ID="E10S6CKR5TLUBG"

log_info "커스텀 도메인 설정 시작: $CUSTOM_DOMAIN"

# 1. SSL 인증서 요청 (us-east-1에서만 가능)
log_info "SSL 인증서 요청 중..."

CERT_ARN=$(aws acm request-certificate \
    --domain-name "$CUSTOM_DOMAIN" \
    --validation-method DNS \
    --region us-east-1 \
    --query 'CertificateArn' \
    --output text)

if [ $? -eq 0 ]; then
    log_success "SSL 인증서 요청 완료: $CERT_ARN"
else
    log_error "SSL 인증서 요청 실패"
    exit 1
fi

log_info "인증서 검증을 위한 DNS 레코드 정보:"
aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.DomainValidationOptions[0].ResourceRecord' \
    --output table

log_warning "DNS 검증을 완료한 후 계속 진행하세요."
read -p "DNS 검증이 완료되었습니까? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "DNS 검증 완료 후 다시 실행해주세요."
    log_info "인증서 ARN: $CERT_ARN"
    exit 0
fi

# 2. 인증서 상태 확인
log_info "인증서 상태 확인 중..."
CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

if [ "$CERT_STATUS" != "ISSUED" ]; then
    log_error "인증서가 아직 발급되지 않았습니다. 상태: $CERT_STATUS"
    log_info "인증서가 발급될 때까지 기다린 후 다시 실행해주세요."
    exit 1
fi

log_success "인증서 발급 완료"

# 3. CloudFront 배포 업데이트
log_info "CloudFront 배포 업데이트 중..."

# 현재 배포 설정 가져오기
aws cloudfront get-distribution-config \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --region us-east-1 > /tmp/cf-current.json

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
' /tmp/cf-current.json > /tmp/cf-updated.json

# 배포 업데이트
aws cloudfront update-distribution \
    --id "$CLOUDFRONT_DISTRIBUTION_ID" \
    --distribution-config file:///tmp/cf-updated.json \
    --if-match "$ETAG" \
    --region us-east-1

if [ $? -eq 0 ]; then
    log_success "CloudFront 배포 업데이트 완료"
else
    log_error "CloudFront 배포 업데이트 실패"
    exit 1
fi

# 4. 결과 저장
echo "CUSTOM_DOMAIN=$CUSTOM_DOMAIN" >> "$PROJECT_ROOT/endpoints.txt"
echo "SSL_CERTIFICATE_ARN=$CERT_ARN" >> "$PROJECT_ROOT/endpoints.txt"

log_success "커스텀 도메인 설정 완료!"
log_info "다음 단계:"
log_info "1. DNS에서 $CUSTOM_DOMAIN을 d9am5o27m55dc.cloudfront.net으로 CNAME 설정"
log_info "2. CloudFront 배포 업데이트가 완료될 때까지 대기 (10-15분)"
log_info "3. https://$CUSTOM_DOMAIN 에서 사이트 확인"

# 정리
rm -f /tmp/cf-current.json /tmp/cf-updated.json

log_info "배포 상태 확인: aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --region us-east-1 --query 'Distribution.Status'"