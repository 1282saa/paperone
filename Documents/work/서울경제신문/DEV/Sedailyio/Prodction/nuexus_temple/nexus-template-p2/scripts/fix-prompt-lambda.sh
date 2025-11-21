#!/bin/bash

# ============================================
# Prompt Lambda 환경 변수 및 CORS 수정 스크립트
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
echo -e "${BLUE}Prompt Lambda 환경 변수 수정${NC}"
echo -e "${BLUE}======================================${NC}"

# Lambda 환경 변수 업데이트
echo -e "${YELLOW}w1-prompt-crud 환경 변수 업데이트 중...${NC}"

aws lambda update-function-configuration \
    --function-name w1-prompt-crud \
    --environment "Variables={
        CONVERSATIONS_TABLE=w1-conversations-v2,
        PROMPTS_TABLE=w1-prompts-v2,
        FILES_TABLE=w1-files,
        MESSAGES_TABLE=w1-messages,
        USAGE_TABLE=w1-usage,
        WEBSOCKET_TABLE=w1-websocket-connections,
        CONNECTIONS_TABLE=w1-websocket-connections,
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
    echo -e "${GREEN}✓ w1-prompt-crud 환경 변수 업데이트 완료${NC}"
else
    echo -e "${RED}✗ w1-prompt-crud 환경 변수 업데이트 실패${NC}"
fi

# Lambda 함수 재시작을 위한 대기
echo -e "${YELLOW}Lambda 함수 재시작 대기 중...${NC}"
sleep 3

# 테스트 - OPTIONS 요청
echo -e "${YELLOW}CORS 테스트 중...${NC}"
curl -X OPTIONS \
    https://16ayefk5lc.execute-api.us-east-1.amazonaws.com/prod/prompts \
    -H "Origin: https://d9am5o27m55dc.cloudfront.net" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -v 2>&1 | grep -i "access-control" || echo -e "${YELLOW}CORS 헤더 없음${NC}"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ 설정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"