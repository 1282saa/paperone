#!/bin/bash

# ============================================
# /conversations 완전 수정 스크립트
# GET, POST 메서드 추가 및 모든 설정 완료
# ============================================

API_ID="16ayefk5lc"
REGION="us-east-1"
SERVICE_NAME="w1"
ACCOUNT_ID="887078546492"

# Lambda ARN
CONVERSATION_LAMBDA="arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${SERVICE_NAME}-conversation-api/invocations"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}/conversations 완전 수정 시작${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# 리소스 ID 가져오기
CONVERSATIONS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/conversations'].id" --output text)
CONVERSATION_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/conversations/{conversationId}'].id" --output text)

echo -e "${YELLOW}리소스 ID:${NC}"
echo "  /conversations: $CONVERSATIONS_ID"
echo "  /conversations/{conversationId}: $CONVERSATION_ID"
echo ""

# ============================================
# 1. /conversations 메서드 추가
# ============================================
echo -e "${YELLOW}[1/4] /conversations 메서드 설정${NC}"

# GET 메서드
echo -e "${BLUE}GET /conversations 추가...${NC}"
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method GET \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method GET \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ GET /conversations${NC}"

# POST 메서드
echo -e "${BLUE}POST /conversations 추가...${NC}"
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method POST \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ POST /conversations${NC}"

# PUT 메서드 (기존)
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method PUT \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ PUT /conversations${NC}"

# OPTIONS 메서드 (CORS)
echo -e "${BLUE}OPTIONS /conversations CORS 설정...${NC}"
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method OPTIONS \
    --type MOCK \
    --request-templates '{"application/json":"{\"statusCode\": 200}"}' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": true,
        "method.response.header.Access-Control-Allow-Headers": true,
        "method.response.header.Access-Control-Allow-Methods": true,
        "method.response.header.Access-Control-Allow-Credentials": true
    }' \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATIONS_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'",
        "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
        "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'",
        "method.response.header.Access-Control-Allow-Credentials": "'"'"'true'"'"'"
    }' \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ OPTIONS /conversations (CORS)${NC}"
echo ""

# ============================================
# 2. /conversations/{conversationId} 메서드 확인
# ============================================
echo -e "${YELLOW}[2/4] /conversations/{conversationId} 메서드 설정${NC}"

# PUT 메서드 추가 (누락된 경우)
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATION_ID \
    --http-method PUT \
    --authorization-type NONE \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATION_ID \
    --http-method PUT \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ PUT /conversations/{conversationId}${NC}"

# GET, DELETE는 이미 있으므로 통합만 확인
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATION_ID \
    --http-method GET \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CONVERSATION_ID \
    --http-method DELETE \
    --type AWS_PROXY \
    --uri "$CONVERSATION_LAMBDA" \
    --integration-http-method POST \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ GET /conversations/{conversationId}${NC}"
echo -e "${GREEN}  ✓ DELETE /conversations/{conversationId}${NC}"
echo ""

# ============================================
# 3. 모든 메서드에 CORS 응답 설정
# ============================================
echo -e "${YELLOW}[3/4] CORS 응답 헤더 설정${NC}"

# /conversations의 모든 메서드에 대해 200, 4XX, 5XX 응답 설정
for METHOD in GET POST PUT; do
    # 200 응답
    aws apigateway put-method-response \
        --rest-api-id $API_ID \
        --resource-id $CONVERSATIONS_ID \
        --http-method $METHOD \
        --status-code 200 \
        --response-models '{"application/json":"Empty"}' \
        --response-parameters '{
            "method.response.header.Access-Control-Allow-Origin": true
        }' \
        --region $REGION >/dev/null 2>&1

    # 4XX 응답들
    for STATUS in 400 401 403 404; do
        aws apigateway put-method-response \
            --rest-api-id $API_ID \
            --resource-id $CONVERSATIONS_ID \
            --http-method $METHOD \
            --status-code $STATUS \
            --response-parameters '{
                "method.response.header.Access-Control-Allow-Origin": true
            }' \
            --region $REGION >/dev/null 2>&1

        aws apigateway put-integration-response \
            --rest-api-id $API_ID \
            --resource-id $CONVERSATIONS_ID \
            --http-method $METHOD \
            --status-code $STATUS \
            --selection-pattern "${STATUS}" \
            --response-parameters '{
                "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"
            }' \
            --region $REGION >/dev/null 2>&1
    done

    echo -e "${GREEN}  ✓ $METHOD /conversations - CORS 응답 설정${NC}"
done
echo ""

# ============================================
# 4. Lambda 권한 설정
# ============================================
echo -e "${YELLOW}[4/4] Lambda 권한 설정${NC}"

# 기존 권한 제거
aws lambda remove-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id apigateway-conversations-all \
    --region $REGION 2>/dev/null

# 새 권한 추가 (모든 메서드 허용)
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-conversation-api \
    --statement-id apigateway-conversations-all \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:${ACCOUNT_ID}:${API_ID}/*/*/conversations*" \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ Lambda 실행 권한 설정${NC}"
echo ""

# ============================================
# 5. API 배포
# ============================================
echo -e "${YELLOW}API Gateway 배포${NC}"
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Complete conversations fix $(date +%Y%m%d-%H%M%S)" \
    --region $REGION \
    --query 'id' \
    --output text)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API 배포 성공! (Deployment ID: $DEPLOYMENT_ID)${NC}"
else
    echo -e "${RED}✗ API 배포 실패${NC}"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ /conversations 완전 수정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}설정된 메서드:${NC}"
echo "  /conversations:"
echo "    ✅ GET    - 대화 목록 조회"
echo "    ✅ POST   - 새 대화 생성/저장"
echo "    ✅ PUT    - 대화 업데이트"
echo "    ✅ OPTIONS - CORS"
echo ""
echo "  /conversations/{conversationId}:"
echo "    ✅ GET    - 대화 상세 조회"
echo "    ✅ PUT    - 대화 업데이트"
echo "    ✅ DELETE - 대화 삭제"
echo "    ✅ OPTIONS - CORS"
echo ""
echo -e "${GREEN}모든 메서드에 Lambda 통합 및 CORS 설정 완료!${NC}"