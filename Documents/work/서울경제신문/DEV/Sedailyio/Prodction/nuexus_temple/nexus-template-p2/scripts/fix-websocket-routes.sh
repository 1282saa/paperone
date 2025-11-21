#!/bin/bash

# ============================================
# WebSocket API 라우트 수정 스크립트
# ============================================

API_ID="prsebeg7ub"
REGION="us-east-1"
SERVICE_NAME="w1"

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}WebSocket API 라우트 설정 시작${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Lambda 함수 ARN
CONNECT_LAMBDA="arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-websocket-connect"
DISCONNECT_LAMBDA="arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-websocket-disconnect"
MESSAGE_LAMBDA="arn:aws:lambda:${REGION}:887078546492:function:${SERVICE_NAME}-websocket-message"

# Integration 생성 함수
create_integration() {
    local LAMBDA_ARN=$1
    local INTEGRATION_TYPE="AWS_PROXY"

    INTEGRATION_ID=$(aws apigatewayv2 create-integration \
        --api-id $API_ID \
        --integration-type $INTEGRATION_TYPE \
        --integration-uri "arn:aws:apigateway:${REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
        --integration-method POST \
        --payload-format-version "1.0" \
        --region $REGION \
        --query 'IntegrationId' \
        --output text 2>/dev/null)

    echo $INTEGRATION_ID
}

# ============================================
# 1. $connect 라우트 생성
# ============================================
echo -e "${YELLOW}[1/4] \$connect 라우트 생성${NC}"

# Integration 생성
CONNECT_INTEGRATION_ID=$(create_integration $CONNECT_LAMBDA)
echo -e "${BLUE}Connect Integration ID: $CONNECT_INTEGRATION_ID${NC}"

# Route 생성
aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key '$connect' \
    --authorization-type NONE \
    --target "integrations/${CONNECT_INTEGRATION_ID}" \
    --region $REGION >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ \$connect 라우트 생성 완료${NC}"
else
    echo -e "${YELLOW}! \$connect 라우트가 이미 존재할 수 있습니다${NC}"
fi

# Lambda 권한 추가
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-websocket-connect \
    --statement-id "apigateway-connect" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*" \
    --region $REGION >/dev/null 2>&1

# ============================================
# 2. $disconnect 라우트 생성
# ============================================
echo -e "${YELLOW}[2/4] \$disconnect 라우트 생성${NC}"

# Integration 생성
DISCONNECT_INTEGRATION_ID=$(create_integration $DISCONNECT_LAMBDA)
echo -e "${BLUE}Disconnect Integration ID: $DISCONNECT_INTEGRATION_ID${NC}"

# Route 생성
aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key '$disconnect' \
    --authorization-type NONE \
    --target "integrations/${DISCONNECT_INTEGRATION_ID}" \
    --region $REGION >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ \$disconnect 라우트 생성 완료${NC}"
else
    echo -e "${YELLOW}! \$disconnect 라우트가 이미 존재할 수 있습니다${NC}"
fi

# Lambda 권한 추가
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-websocket-disconnect \
    --statement-id "apigateway-disconnect" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*" \
    --region $REGION >/dev/null 2>&1

# ============================================
# 3. $default 라우트 생성
# ============================================
echo -e "${YELLOW}[3/4] \$default 라우트 생성${NC}"

# Integration 생성
MESSAGE_INTEGRATION_ID=$(create_integration $MESSAGE_LAMBDA)
echo -e "${BLUE}Message Integration ID: $MESSAGE_INTEGRATION_ID${NC}"

# Route 생성
aws apigatewayv2 create-route \
    --api-id $API_ID \
    --route-key '$default' \
    --authorization-type NONE \
    --target "integrations/${MESSAGE_INTEGRATION_ID}" \
    --region $REGION >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ \$default 라우트 생성 완료${NC}"
else
    echo -e "${YELLOW}! \$default 라우트가 이미 존재할 수 있습니다${NC}"
fi

# Lambda 권한 추가
aws lambda add-permission \
    --function-name ${SERVICE_NAME}-websocket-message \
    --statement-id "apigateway-message" \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:${REGION}:887078546492:${API_ID}/*" \
    --region $REGION >/dev/null 2>&1

# ============================================
# 4. API 재배포
# ============================================
echo -e "${YELLOW}[4/4] WebSocket API 재배포${NC}"

# 기존 deployment 확인
DEPLOYMENT_ID=$(aws apigatewayv2 get-deployments \
    --api-id $API_ID \
    --region $REGION \
    --query 'Items[0].DeploymentId' \
    --output text)

if [ "$DEPLOYMENT_ID" != "None" ] && [ -n "$DEPLOYMENT_ID" ]; then
    echo -e "${BLUE}기존 Deployment ID: $DEPLOYMENT_ID${NC}"
else
    # 새 deployment 생성
    DEPLOYMENT_ID=$(aws apigatewayv2 create-deployment \
        --api-id $API_ID \
        --region $REGION \
        --query 'DeploymentId' \
        --output text)
    echo -e "${GREEN}새 Deployment 생성: $DEPLOYMENT_ID${NC}"
fi

# Stage 업데이트
aws apigatewayv2 update-stage \
    --api-id $API_ID \
    --stage-name prod \
    --deployment-id $DEPLOYMENT_ID \
    --region $REGION >/dev/null 2>&1

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✓ WebSocket API 라우트 설정 완료!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "${BLUE}WebSocket API 정보:${NC}"
echo "  API ID: $API_ID"
echo "  Endpoint: wss://${API_ID}.execute-api.${REGION}.amazonaws.com/prod"
echo ""
echo -e "${BLUE}설정된 라우트:${NC}"
echo "  - \$connect    -> ${SERVICE_NAME}-websocket-connect"
echo "  - \$disconnect -> ${SERVICE_NAME}-websocket-disconnect"
echo "  - \$default    -> ${SERVICE_NAME}-websocket-message"
echo ""

# 라우트 확인
echo -e "${YELLOW}라우트 확인 중...${NC}"
aws apigatewayv2 get-routes \
    --api-id $API_ID \
    --region $REGION \
    --query 'Items[*].[RouteKey,Target]' \
    --output table

echo -e "${GREEN}✓ 모든 설정 완료${NC}"