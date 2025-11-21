#!/bin/bash

# SSL 인증서 확인 및 도메인 설정 스크립트

source "$(dirname "$0")/00-config.sh"

CERT_ARN="arn:aws:acm:us-east-1:887078546492:certificate/c25d833a-74d8-4d95-a923-0204d806ea89"
CUSTOM_DOMAIN="w1.sedaily.ai"
API_DOMAIN="api.w1.sedaily.ai"
WS_DOMAIN="ws.w1.sedaily.ai"

log_info "SSL 인증서 상태 확인 중..."

# 인증서 상태 확인
STATUS=$(aws acm describe-certificate \
    --certificate-arn "$CERT_ARN" \
    --region us-east-1 \
    --query 'Certificate.Status' \
    --output text)

log_info "현재 인증서 상태: $STATUS"

if [ "$STATUS" != "ISSUED" ]; then
    log_warning "인증서가 아직 발급되지 않았습니다. 잠시 후 다시 시도해주세요."
    log_info "상태 확인: aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1 --query 'Certificate.Status'"
    exit 0
fi

log_success "SSL 인증서 발급 완료!"

# API Gateway 커스텀 도메인 설정
log_info "API Gateway 커스텀 도메인 설정 중..."

# REST API 커스텀 도메인
aws apigateway create-domain-name \
    --domain-name "$API_DOMAIN" \
    --certificate-arn "$CERT_ARN" \
    --security-policy TLS_1_2 \
    --region us-east-1 2>/dev/null

# WebSocket API 커스텀 도메인  
aws apigatewayv2 create-domain-name \
    --domain-name "$WS_DOMAIN" \
    --domain-name-configurations CertificateArn="$CERT_ARN",SecurityPolicy=TLS_1_2 \
    --region us-east-1 2>/dev/null

# API ID 가져오기
if [ -f ".api-ids" ]; then
    source .api-ids
fi

# 베이스 패스 매핑
if [ -n "$REST_API_ID" ]; then
    log_info "REST API 베이스 패스 매핑: $REST_API_ID"
    aws apigateway create-base-path-mapping \
        --domain-name "$API_DOMAIN" \
        --rest-api-id "$REST_API_ID" \
        --stage prod \
        --region us-east-1 2>/dev/null
fi

if [ -n "$WEBSOCKET_API_ID" ]; then
    log_info "WebSocket API 매핑: $WEBSOCKET_API_ID"
    aws apigatewayv2 create-api-mapping \
        --domain-name "$WS_DOMAIN" \
        --api-id "$WEBSOCKET_API_ID" \
        --stage prod \
        --region us-east-1 2>/dev/null
fi

# 도메인 정보 가져오기
API_TARGET=$(aws apigateway get-domain-name \
    --domain-name "$API_DOMAIN" \
    --region us-east-1 \
    --query 'distributionDomainName' \
    --output text 2>/dev/null)

WS_TARGET=$(aws apigatewayv2 get-domain-name \
    --domain-name "$WS_DOMAIN" \
    --region us-east-1 \
    --query 'DomainNameConfigurations[0].TargetDomainName' \
    --output text 2>/dev/null)

log_success "커스텀 도메인 설정 완료!"
log_info ""
log_info "=== DNS 레코드 설정 필요 ==="
log_info "다음 CNAME 레코드를 Route 53에 추가하세요:"
log_info ""
if [ -n "$API_TARGET" ]; then
    log_info "api.w1.sedaily.ai -> $API_TARGET"
fi
if [ -n "$WS_TARGET" ]; then
    log_info "ws.w1.sedaily.ai -> $WS_TARGET"
fi

# DNS 레코드 자동 추가
log_info ""
read -p "DNS 레코드를 자동으로 추가하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "DNS 레코드 추가 중..."
    
    HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
        --query 'HostedZones[?Name==`sedaily.ai.`].Id' \
        --output text | sed 's|/hostedzone/||')
    
    if [ -n "$API_TARGET" ]; then
        aws route53 change-resource-record-sets \
            --hosted-zone-id "$HOSTED_ZONE_ID" \
            --change-batch "{
                \"Changes\": [{
                    \"Action\": \"CREATE\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"$API_DOMAIN\",
                        \"Type\": \"CNAME\",
                        \"TTL\": 300,
                        \"ResourceRecords\": [{\"Value\": \"$API_TARGET\"}]
                    }
                }]
            }" >/dev/null
        log_success "API 도메인 DNS 레코드 추가 완료"
    fi
    
    if [ -n "$WS_TARGET" ]; then
        aws route53 change-resource-record-sets \
            --hosted-zone-id "$HOSTED_ZONE_ID" \
            --change-batch "{
                \"Changes\": [{
                    \"Action\": \"CREATE\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"$WS_DOMAIN\",
                        \"Type\": \"CNAME\",
                        \"TTL\": 300,
                        \"ResourceRecords\": [{\"Value\": \"$WS_TARGET\"}]
                    }
                }]
            }" >/dev/null
        log_success "WebSocket 도메인 DNS 레코드 추가 완료"
    fi
fi

log_info ""
log_success "w1.sedaily.ai 도메인 설정 완료!"
log_info "테스트: curl https://api.w1.sedaily.ai/health"