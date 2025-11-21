#!/bin/bash

# ============================================
# P2 서비스 Perplexity API 키 업데이트 스크립트
# b1.sedaily.ai 도메인용
# ============================================

REGION="us-east-1"
PERPLEXITY_API_KEY=${1}

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$PERPLEXITY_API_KEY" ]; then
    echo -e "${RED}❌ 사용법: $0 [Perplexity API 키]${NC}"
    echo ""
    echo "예시:"
    echo "  $0 pplx-your-api-key-here"
    echo ""
    echo "현재 p2 서비스 (b1.sedaily.ai)에 Perplexity API 키를 설정합니다."
    exit 1
fi

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}P2 서비스 Perplexity API 키 업데이트${NC}"
echo -e "${BLUE}======================================${NC}"
echo "도메인: ${GREEN}b1.sedaily.ai${NC}"
echo "서비스: ${GREEN}p2-two${NC}"
echo "리전: $REGION"
echo "API 키: ${GREEN}${PERPLEXITY_API_KEY:0:10}...${NC}"
echo ""

# P2 서비스의 실제 Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "p2-two-conversation-api-two"
    "p2-two-websocket-disconnect-two"
    "p2-two-usage-handler-two"
    "p2-two-websocket-message-two"
    "p2-two-websocket-connect-two"
    "p2-two-prompt-crud-two"
)

# 각 Lambda 함수의 환경변수에 Perplexity API 키 추가
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    echo -e "${YELLOW}$FUNCTION 환경변수 업데이트 중...${NC}"

    # 현재 환경변수 가져오기
    CURRENT_ENV=$(aws lambda get-function-configuration \
        --function-name $FUNCTION \
        --region $REGION \
        --query 'Environment.Variables' \
        --output json 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ $FUNCTION 함수를 찾을 수 없습니다${NC}"
        continue
    fi

    # Perplexity API 키 추가
    UPDATED_ENV=$(echo $CURRENT_ENV | jq --arg key "$PERPLEXITY_API_KEY" '. + {"PERPLEXITY_API_KEY": $key}')

    # 환경변수 업데이트
    aws lambda update-function-configuration \
        --function-name $FUNCTION \
        --environment "Variables=$UPDATED_ENV" \
        --region $REGION \
        --output text >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $FUNCTION 업데이트 완료${NC}"
        
        # 설정 확인
        VERIFY_KEY=$(aws lambda get-function-configuration \
            --function-name $FUNCTION \
            --region $REGION \
            --query 'Environment.Variables.PERPLEXITY_API_KEY' \
            --output text 2>/dev/null)
        
        if [ "$VERIFY_KEY" != "None" ] && [ -n "$VERIFY_KEY" ]; then
            echo -e "  ${GREEN}→ API 키 설정 확인됨: ${VERIFY_KEY:0:10}...${NC}"
        else
            echo -e "  ${RED}→ API 키 설정 실패${NC}"
        fi
    else
        echo -e "${RED}✗ $FUNCTION 업데이트 실패${NC}"
    fi

    sleep 1
done

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ P2 서비스 Perplexity API 키 설정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# WebSocket 함수 테스트 (Perplexity 기능이 주로 사용되는 곳)
echo -e "${YELLOW}WebSocket 메시지 함수 테스트...${NC}"

TEST_PAYLOAD=$(cat <<EOF
{
    "requestContext": {
        "connectionId": "test123",
        "eventType": "MESSAGE"
    },
    "body": "{\"action\":\"sendMessage\",\"message\":\"테스트 메시지\",\"conversationId\":\"test\"}"
}
EOF
)

aws lambda invoke \
    --function-name p2-two-websocket-message-two \
    --payload "$TEST_PAYLOAD" \
    --region $REGION \
    /tmp/p2-perplexity-test-response.json >/dev/null 2>&1

if [ -f /tmp/p2-perplexity-test-response.json ]; then
    RESPONSE=$(cat /tmp/p2-perplexity-test-response.json)
    if [[ $RESPONSE == *"statusCode"* ]]; then
        echo -e "${GREEN}✓ Lambda 함수 응답 정상${NC}"
    else
        echo -e "${YELLOW}⚠ Lambda 함수 응답: $RESPONSE${NC}"
    fi
    rm /tmp/p2-perplexity-test-response.json
fi

echo ""
echo -e "${BLUE}💡 확인 방법:${NC}"
echo "1. CloudWatch 로그 확인:"
echo "   aws logs tail /aws/lambda/p2-two-websocket-message-two --follow"
echo ""
echo "2. 프론트엔드 테스트:"
echo "   https://b1.sedaily.ai 접속 후 최신 정보 질문"
echo ""
echo "3. API 엔드포인트:"
echo "   REST API: https://pisnqqgu75.execute-api.us-east-1.amazonaws.com/prod"
echo "   WebSocket: wss://dwc2m51as4.execute-api.us-east-1.amazonaws.com/prod"
echo ""
echo -e "${GREEN}P2 서비스에 Perplexity API가 성공적으로 설정되었습니다!${NC}"