#!/bin/bash

# DNS 검증 레코드 추가 스크립트

source "$(dirname "$0")/00-config.sh"

CERT_ARN="arn:aws:acm:us-east-1:887078546492:certificate/c25d833a-74d8-4d95-a923-0204d806ea89"
VALIDATION_NAME="_38633f378cb4b9ca8080cb36e7c6a345.w1.sedaily.ai."
VALIDATION_VALUE="_228d5c744bee29ca99f8cd1f38a8f566.xlfgrmvvlj.acm-validations.aws."

log_info "DNS 검증 레코드 추가 중..."

# sedaily.ai 호스팅 존 ID 찾기
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
    --query 'HostedZones[?Name==`sedaily.ai.`].Id' \
    --output text | sed 's|/hostedzone/||')

if [ -z "$HOSTED_ZONE_ID" ]; then
    log_error "sedaily.ai 호스팅 존을 찾을 수 없습니다"
    exit 1
fi

log_info "호스팅 존 ID: $HOSTED_ZONE_ID"

# DNS 검증 레코드 추가
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch "{
        \"Changes\": [{
            \"Action\": \"CREATE\",
            \"ResourceRecordSet\": {
                \"Name\": \"$VALIDATION_NAME\",
                \"Type\": \"CNAME\",
                \"TTL\": 300,
                \"ResourceRecords\": [{\"Value\": \"$VALIDATION_VALUE\"}]
            }
        }]
    }"

if [ $? -eq 0 ]; then
    log_success "DNS 검증 레코드 추가 완료"
    log_info "인증서 검증 대기 중... (최대 10분 소요)"
    
    # 인증서 상태 확인
    while true; do
        STATUS=$(aws acm describe-certificate \
            --certificate-arn "$CERT_ARN" \
            --region us-east-1 \
            --query 'Certificate.Status' \
            --output text)
        
        log_info "인증서 상태: $STATUS"
        
        if [ "$STATUS" = "ISSUED" ]; then
            log_success "SSL 인증서 발급 완료!"
            break
        elif [ "$STATUS" = "FAILED" ]; then
            log_error "SSL 인증서 발급 실패"
            exit 1
        fi
        
        sleep 30
    done
else
    log_error "DNS 검증 레코드 추가 실패"
    exit 1
fi

log_info "다음 단계: CloudFront 및 API Gateway 커스텀 도메인 설정"