#!/bin/bash

API_ID="16ayefk5lc"
REGION="us-east-1"
LAMBDA_ARN="arn:aws:lambda:us-east-1:887078546492:function:tem1-conversation-api"

echo "Adding PATCH method to /conversations/{conversationId} endpoint..."

# Find the resource ID for /conversations/{conversationId}
RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --region $REGION \
  --query "items[?path=='/conversations/{conversationId}'].id" \
  --output text)

echo "Resource ID: $RESOURCE_ID"

# Add PATCH method
echo "Adding PATCH method..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method PATCH \
  --authorization-type NONE \
  --region $REGION

# Add method response
echo "Adding method response..."
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method PATCH \
  --status-code 200 \
  --response-models '{"application/json":"Empty"}' \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false,"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false}' \
  --region $REGION

# Add integration
echo "Adding Lambda integration..."
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method PATCH \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
  --region $REGION

# Add integration response
echo "Adding integration response..."
aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method PATCH \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,PATCH,DELETE,OPTIONS'"'"'"}' \
  --region $REGION

# Add DELETE method as well
echo "Adding DELETE method..."
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method DELETE \
  --authorization-type NONE \
  --region $REGION

# Add method response for DELETE
aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method DELETE \
  --status-code 200 \
  --response-models '{"application/json":"Empty"}' \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":false,"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false}' \
  --region $REGION

# Add integration for DELETE
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method DELETE \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
  --region $REGION

# Add integration response for DELETE
aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $RESOURCE_ID \
  --http-method DELETE \
  --status-code 200 \
  --response-parameters '{"method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'","method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,PATCH,DELETE,OPTIONS'"'"'"}' \
  --region $REGION

# Add Lambda permission for PATCH
echo "Adding Lambda permission for PATCH..."
aws lambda add-permission \
  --function-name tem1-conversation-api \
  --statement-id "api-gateway-patch-$RESOURCE_ID" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:887078546492:$API_ID/*/PATCH/conversations/{conversationId}" \
  --region $REGION 2>/dev/null || true

# Add Lambda permission for DELETE
echo "Adding Lambda permission for DELETE..."
aws lambda add-permission \
  --function-name tem1-conversation-api \
  --statement-id "api-gateway-delete-$RESOURCE_ID" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:887078546492:$API_ID/*/DELETE/conversations/{conversationId}" \
  --region $REGION 2>/dev/null || true

# Deploy changes
echo "Deploying API changes..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "PATCH and DELETE methods added successfully!"