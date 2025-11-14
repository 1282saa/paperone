#!/bin/bash

# ============================================
# 프롬프트 API 통합 문제 해결 스크립트
# ============================================

SERVICE_NAME="w1"
REGION="us-east-1"
API_ID="16ayefk5lc"
FUNCTION_ARN="arn:aws:lambda:us-east-1:887078546492:function:w1-prompt-crud"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}프롬프트 API 통합 수정 시작${NC}"
echo -e "${BLUE}======================================${NC}"

# ============================================
# 1. 모든 프롬프트 관련 리소스 ID 가져오기
# ============================================
echo -e "${YELLOW}[1/5] 리소스 ID 확인${NC}"

# /prompts
PROMPTS_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/prompts'].id" --output text)
echo "  /prompts: $PROMPTS_ID"

# /prompts/{promptId}
PROMPT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/prompts/{promptId}'].id" --output text)
echo "  /prompts/{promptId}: $PROMPT_ID"

# /prompts/{promptId}/files
PROMPT_FILES_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/prompts/{promptId}/files'].id" --output text)
echo "  /prompts/{promptId}/files: $PROMPT_FILES_ID"

# /prompts/{promptId}/files/{fileId}
PROMPT_FILE_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query "items[?path=='/prompts/{promptId}/files/{fileId}'].id" --output text)
echo "  /prompts/{promptId}/files/{fileId}: $PROMPT_FILE_ID"

# ============================================
# 2. /prompts 엔드포인트 통합 설정
# ============================================
echo -e "${YELLOW}[2/5] /prompts 엔드포인트 통합 설정${NC}"

# GET /prompts
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROMPTS_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ GET /prompts${NC}"

# POST /prompts
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROMPTS_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ POST /prompts${NC}"

# OPTIONS /prompts (CORS)
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $PROMPTS_ID \
    --http-method OPTIONS \
    --patch-operations op=replace,path=/authorizationType,value=NONE \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ OPTIONS /prompts (인증 비활성화)${NC}"

# ============================================
# 3. /prompts/{promptId} 엔드포인트 통합 설정
# ============================================
echo -e "${YELLOW}[3/5] /prompts/{promptId} 엔드포인트 통합 설정${NC}"

# GET /prompts/{promptId}
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROMPT_ID \
    --http-method GET \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ GET /prompts/{promptId}${NC}"

# POST /prompts/{promptId}
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROMPT_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ POST /prompts/{promptId}${NC}"

# PUT /prompts/{promptId}
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $PROMPT_ID \
    --http-method PUT \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ PUT /prompts/{promptId}${NC}"

# OPTIONS /prompts/{promptId} (CORS)
aws apigateway update-method \
    --rest-api-id $API_ID \
    --resource-id $PROMPT_ID \
    --http-method OPTIONS \
    --patch-operations op=replace,path=/authorizationType,value=NONE \
    --region $REGION >/dev/null 2>&1
echo -e "${GREEN}  ✓ OPTIONS /prompts/{promptId} (인증 비활성화)${NC}"

# ============================================
# 4. Files 엔드포인트 통합 설정 (필요시)
# ============================================
if [ ! -z "$PROMPT_FILES_ID" ]; then
    echo -e "${YELLOW}[4/5] Files 엔드포인트 통합 설정${NC}"

    # GET /prompts/{promptId}/files
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILES_ID \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ GET /prompts/{promptId}/files${NC}"

    # POST /prompts/{promptId}/files
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILES_ID \
        --http-method POST \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ POST /prompts/{promptId}/files${NC}"

    # OPTIONS 인증 비활성화
    aws apigateway update-method \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILES_ID \
        --http-method OPTIONS \
        --patch-operations op=replace,path=/authorizationType,value=NONE \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ OPTIONS /prompts/{promptId}/files (인증 비활성화)${NC}"
fi

if [ ! -z "$PROMPT_FILE_ID" ]; then
    # GET /prompts/{promptId}/files/{fileId}
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILE_ID \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ GET /prompts/{promptId}/files/{fileId}${NC}"

    # PUT /prompts/{promptId}/files/{fileId}
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILE_ID \
        --http-method PUT \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ PUT /prompts/{promptId}/files/{fileId}${NC}"

    # DELETE /prompts/{promptId}/files/{fileId}
    aws apigateway put-integration \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILE_ID \
        --http-method DELETE \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${FUNCTION_ARN}/invocations" \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ DELETE /prompts/{promptId}/files/{fileId}${NC}"

    # OPTIONS 인증 비활성화
    aws apigateway update-method \
        --rest-api-id $API_ID \
        --resource-id $PROMPT_FILE_ID \
        --http-method OPTIONS \
        --patch-operations op=replace,path=/authorizationType,value=NONE \
        --region $REGION >/dev/null 2>&1
    echo -e "${GREEN}  ✓ OPTIONS /prompts/{promptId}/files/{fileId} (인증 비활성화)${NC}"
fi

# ============================================
# 5. Lambda 권한 설정
# ============================================
echo -e "${YELLOW}[5/5] Lambda 권한 설정${NC}"

# 기존 권한 제거 (에러 무시)
aws lambda remove-permission \
    --function-name w1-prompt-crud \
    --statement-id api-gateway-invoke-prompts \
    --region $REGION 2>/dev/null

# 새 권한 추가
aws lambda add-permission \
    --function-name w1-prompt-crud \
    --statement-id api-gateway-invoke-prompts \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*/*" \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}  ✓ Lambda 실행 권한 설정 완료${NC}"

# ============================================
# 6. API Gateway 배포
# ============================================
echo -e "${YELLOW}API Gateway 배포 중...${NC}"

# 배포 생성
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name prod \
    --description "Prompt API integration fix" \
    --region $REGION \
    --query 'id' \
    --output text 2>/dev/null)

if [ ! -z "$DEPLOYMENT_ID" ]; then
    echo -e "${GREEN}✓ API 배포 완료 (Deployment ID: $DEPLOYMENT_ID)${NC}"
else
    echo -e "${RED}✗ API 배포 실패${NC}"
fi

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ 프롬프트 API 통합 수정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"