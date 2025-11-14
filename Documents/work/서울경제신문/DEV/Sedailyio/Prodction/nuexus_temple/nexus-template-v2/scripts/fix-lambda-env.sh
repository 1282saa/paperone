#!/bin/bash

# ============================================
# Lambda 환경 변수 수정 스크립트
# ============================================

SERVICE_NAME="w1"
REGION="us-east-1"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Lambda 환경 변수 수정 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 함수 목록
LAMBDA_FUNCTIONS=(
    "w1-conversation-api"
    "w1-websocket-disconnect"
    "w1-usage-handler"
    "w1-websocket-message"
    "w1-websocket-connect"
    "w1-prompt-crud"
)

# 환경 변수 설정
for FUNCTION in "${LAMBDA_FUNCTIONS[@]}"; do
    echo -e "${YELLOW}$FUNCTION 환경 변수 업데이트 중...${NC}"

    aws lambda update-function-configuration \
        --function-name $FUNCTION \
        --environment "Variables={
            CONVERSATIONS_TABLE=w1-conversations-v2,
            PROMPTS_TABLE=w1-prompts-v2,
            USAGE_TABLE=w1-usage,
            WEBSOCKET_TABLE=w1-websocket-connections,
            CONNECTIONS_TABLE=w1-websocket-connections,
            FILES_TABLE=w1-files,
            MESSAGES_TABLE=w1-messages,
            WEBSOCKET_API_ID=prsebeg7ub,
            REST_API_URL=https://16ayefk5lc.execute-api.us-east-1.amazonaws.com/prod,
            WEBSOCKET_API_URL=wss://prsebeg7ub.execute-api.us-east-1.amazonaws.com/prod,
            LOG_LEVEL=INFO,
            CLOUDWATCH_ENABLED=true,
            SERVICE_NAME=w1,
            ENABLE_NEWS_SEARCH=true,
            DEFAULT_ENGINE_TYPE=11,
            SECONDARY_ENGINE_TYPE=22,
            AVAILABLE_ENGINES=11,22,33
        }" \
        --region $REGION \
        --output text >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $FUNCTION 업데이트 완료${NC}"
    else
        echo -e "${RED}✗ $FUNCTION 업데이트 실패${NC}"
    fi
done

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ Lambda 환경 변수 수정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"

# 테스트 연결
echo -e "${YELLOW}WebSocket 연결 테스트...${NC}"
wscat -c wss://prsebeg7ub.execute-api.us-east-1.amazonaws.com/prod 2>/dev/null &
PID=$!
sleep 2
kill $PID 2>/dev/null

echo -e "${GREEN}설정이 완료되었습니다!${NC}"