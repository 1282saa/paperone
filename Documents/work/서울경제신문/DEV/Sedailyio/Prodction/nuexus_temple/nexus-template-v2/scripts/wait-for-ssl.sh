#!/bin/bash

# SSL 인증서 발급 대기 스크립트

source "$(dirname "$0")/00-config.sh"

CERT_ARN="arn:aws:acm:us-east-1:887078546492:certificate/c25d833a-74d8-4d95-a923-0204d806ea89"
MAX_WAIT=600  # 10분

log_info "SSL 인증서 발급 대기 중..."
log_info "최대 대기 시간: 10분"

start_time=$(date +%s)

while true; do
    STATUS=$(aws acm describe-certificate \
        --certificate-arn "$CERT_ARN" \
        --region us-east-1 \
        --query 'Certificate.Status' \
        --output text)
    
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    log_info "인증서 상태: $STATUS (경과 시간: ${elapsed}초)"
    
    if [ "$STATUS" = "ISSUED" ]; then
        log_success "SSL 인증서 발급 완료!"
        log_info "다음 단계 실행: ./scripts/check-ssl-and-setup-domains.sh"
        exit 0
    elif [ "$STATUS" = "FAILED" ]; then
        log_error "SSL 인증서 발급 실패"
        exit 1
    elif [ $elapsed -gt $MAX_WAIT ]; then
        log_error "최대 대기 시간 초과 (10분)"
        log_info "수동으로 상태 확인: aws acm describe-certificate --certificate-arn $CERT_ARN --region us-east-1"
        exit 1
    fi
    
    sleep 30
done