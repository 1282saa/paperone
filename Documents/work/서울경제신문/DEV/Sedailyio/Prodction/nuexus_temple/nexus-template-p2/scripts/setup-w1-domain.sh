#!/bin/bash

# w1.sedaily.ai 커스텀 도메인 설정 스크립트

source "$(dirname "$0")/00-config.sh"

CUSTOM_DOMAIN="w1.sedaily.ai"
API_DOMAIN="api.w1.sedaily.ai"
WS_DOMAIN="ws.w1.sedaily.ai"

log_info "w1.sedaily.ai 커스텀 도메인 설정 시작"

# 1. SSL 인증서 요청 (us-east-1에서만 가능)
log_info "SSL 인증서 요청 중..."

# 와일드카드 인증서 요청
CERT_ARN=$(aws acm request-certificate \
    --domain-name "*.w1.sedaily.ai" \
    --subject-alternative-names "w1.sedaily.ai" \
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
    --query 'Certificate.DomainValidationOptions' \
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

# 3. API Gateway 커스텀 도메인 설정
log_info "API Gateway 커스텀 도메인 설정 중..."

# REST API 커스텀 도메인
aws apigateway create-domain-name \
    --domain-name "$API_DOMAIN" \
    --certificate-arn "$CERT_ARN" \
    --security-policy TLS_1_2 \
    --region "$REGION"

# WebSocket API 커스텀 도메인
aws apigatewayv2 create-domain-name \
    --domain-name "$WS_DOMAIN" \
    --domain-name-configurations CertificateArn="$CERT_ARN",SecurityPolicy=TLS_1_2 \
    --region "$REGION"

# 4. 베이스 패스 매핑
if [ -n "$REST_API_ID" ]; then
    aws apigateway create-base-path-mapping \
        --domain-name "$API_DOMAIN" \
        --rest-api-id "$REST_API_ID" \
        --stage prod \
        --region "$REGION"
fi

if [ -n "$WEBSOCKET_API_ID" ]; then
    aws apigatewayv2 create-api-mapping \
        --domain-name "$WS_DOMAIN" \
        --api-id "$WEBSOCKET_API_ID" \
        --stage prod \
        --region "$REGION"
fi

# 5. CloudFront 배포 업데이트 (기존 배포가 있는 경우)
if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
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
    ' /tmp/cf-current.json | jq '.DistributionConfig' > /tmp/cf-updated.json
    
    # 배포 업데이트
    aws cloudfront update-distribution \
        --id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --distribution-config file:///tmp/cf-updated.json \
        --if-match "$ETAG" \
        --region us-east-1
    
    rm -f /tmp/cf-current.json /tmp/cf-updated.json
fi

# 6. 도메인 정보 가져오기
API_TARGET=$(aws apigateway get-domain-name \
    --domain-name "$API_DOMAIN" \
    --region "$REGION" \
    --query 'distributionDomainName' \
    --output text 2>/dev/null)

WS_TARGET=$(aws apigatewayv2 get-domain-name \
    --domain-name "$WS_DOMAIN" \
    --region "$REGION" \
    --query 'DomainNameConfigurations[0].TargetDomainName' \
    --output text 2>/dev/null)

# 7. 환경변수 파일 업데이트
log_info "환경변수 파일 업데이트 중..."

# 백엔드 환경변수 업데이트
cat > "$BACKEND_DIR/.env.w1" << EOF
# w1.sedaily.ai 도메인 설정
CUSTOM_DOMAIN=$CUSTOM_DOMAIN
API_DOMAIN=$API_DOMAIN
WS_DOMAIN=$WS_DOMAIN
SSL_CERTIFICATE_ARN=$CERT_ARN

# API 엔드포인트
REST_API_URL=https://$API_DOMAIN
WEBSOCKET_API_URL=wss://$WS_DOMAIN

# 기존 설정 유지
$(cat "$BACKEND_DIR/.env" | grep -v "REST_API_URL\|WEBSOCKET_API_URL")
EOF

# 프론트엔드 환경변수 업데이트
cat > "$FRONTEND_DIR/.env.w1" << EOF
# w1.sedaily.ai 도메인 설정
VITE_API_BASE_URL=https://$API_DOMAIN
VITE_WS_URL=wss://$WS_DOMAIN
VITE_CUSTOM_DOMAIN=$CUSTOM_DOMAIN

# 기존 설정 유지
$(cat "$FRONTEND_DIR/.env" | grep -v "VITE_API_BASE_URL\|VITE_WS_URL")
EOF

# 8. 결과 저장
cat >> "$PROJECT_ROOT/endpoints.txt" << EOF

# w1.sedaily.ai 도메인 설정
CUSTOM_DOMAIN=$CUSTOM_DOMAIN
API_DOMAIN=$API_DOMAIN
WS_DOMAIN=$WS_DOMAIN
SSL_CERTIFICATE_ARN=$CERT_ARN
API_TARGET_DOMAIN=$API_TARGET
WS_TARGET_DOMAIN=$WS_TARGET
EOF

log_success "w1.sedaily.ai 커스텀 도메인 설정 완료!"
log_info ""
log_info "다음 DNS 레코드를 설정해주세요:"
log_info "1. $CUSTOM_DOMAIN -> CloudFront 도메인 (CNAME)"
if [ -n "$API_TARGET" ]; then
    log_info "2. $API_DOMAIN -> $API_TARGET (CNAME)"
fi
if [ -n "$WS_TARGET" ]; then
    log_info "3. $WS_DOMAIN -> $WS_TARGET (CNAME)"
fi
log_info ""
log_info "설정 완료 후 접속 URL:"
log_info "- 메인 사이트: https://$CUSTOM_DOMAIN"
log_info "- API: https://$API_DOMAIN"
log_info "- WebSocket: wss://$WS_DOMAIN"