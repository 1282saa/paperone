#!/bin/bash

# ============================================
# CORS 에러 응답 수정 스크립트
# 4XX/5XX 응답에도 CORS 헤더 추가
# ============================================

API_ID="16ayefk5lc"
REGION="us-east-1"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}CORS 에러 응답 수정 시작${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# /conversations 리소스 ID
CONVERSATIONS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/conversations'].id" --output text)
echo -e "${YELLOW}/conversations resource ID: $CONVERSATIONS_ID${NC}"

# /conversations/{conversationId} 리소스 ID
CONVERSATION_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/conversations/{conversationId}'].id" --output text)
echo -e "${YELLOW}/conversations/{conversationId} resource ID: $CONVERSATION_ID${NC}"
echo ""

# ============================================
# POST /conversations 에러 응답 설정
# ============================================
echo -e "${YELLOW}POST /conversations 에러 응답 CORS 설정${NC}"

# 4XX 응답
for STATUS in 400 401 403 404; do
    # Method Response 추가
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method POST \
        --status-code $STATUS \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": true,
            "method.response.header.Access-Control-Allow-Headers": true,
            "method.response.header.Access-Control-Allow-Methods": true
        }' \
        --region $REGION >/dev/null 2>&1

    # Integration Response 추가
    aws apigateway put-integration-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method POST \
        --status-code $STATUS \
        --selection-pattern "${STATUS}" \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'",
            "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
            "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}  ✓ POST /conversations - $STATUS 응답 CORS 설정${NC}"
done

# 5XX 응답
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method POST \
    --status-code 500 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true
    }' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method POST \
    --status-code 500 \
    --selection-pattern "5\\d{2}" \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'",
        "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
        "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'"
    }' \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ POST /conversations - 500 응답 CORS 설정${NC}"
echo ""

# ============================================
# GET /conversations 에러 응답 설정
# ============================================
echo -e "${YELLOW}GET /conversations 에러 응답 CORS 설정${NC}"

for STATUS in 400 401 403 404; do
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method GET \
        --status-code $STATUS \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": true,
            "method.response.header.Access-Control-Allow-Headers": true,
            "method.response.header.Access-Control-Allow-Methods": true
        }' \
        --region $REGION >/dev/null 2>&1

    aws apigateway put-integration-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method GET \
        --status-code $STATUS \
        --selection-pattern "${STATUS}" \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'",
            "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
            "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}  ✓ GET /conversations - $STATUS 응답 CORS 설정${NC}"
done

# ============================================
# PUT /conversations 에러 응답 설정
# ============================================
echo -e "${YELLOW}PUT /conversations 에러 응답 CORS 설정${NC}"

for STATUS in 400 401 403 404; do
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method PUT \
        --status-code $STATUS \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": true,
            "method.response.header.Access-Control-Allow-Headers": true,
            "method.response.header.Access-Control-Allow-Methods": true
        }' \
        --region $REGION >/dev/null 2>&1

    aws apigateway put-integration-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method PUT \
        --status-code $STATUS \
        --selection-pattern "${STATUS}" \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'",
            "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
            "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'"
        }' \
        --region $REGION >/dev/null 2>&1

    echo -e "${GREEN}  ✓ PUT /conversations - $STATUS 응답 CORS 설정${NC}"
done
echo ""

# ============================================
# API Gateway 재배포
# ============================================
echo -e "${YELLOW}API Gateway 재배포${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "CORS error responses fix $(date +%Y%m%d-%H%M%S)" \
    --region $REGION \
    --query 'id' \
    --output text 2>/dev/null)

if [ -n "$DEPLOYMENT_ID" ]; then
    echo -e "${GREEN}✓ API 배포 성공! (Deployment ID: $DEPLOYMENT_ID)${NC}"
else
    echo -e "${RED}✗ API 배포 실패${NC}"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ CORS 에러 응답 수정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}설정 완료:${NC}"
echo "  ✓ 4XX 에러 응답에 CORS 헤더 추가"
echo "  ✓ 5XX 에러 응답에 CORS 헤더 추가"
echo "  ✓ API Gateway 재배포 완료"
echo ""
echo -e "${YELLOW}이제 403 에러가 발생해도 CORS 헤더가 포함됩니다!${NC}"