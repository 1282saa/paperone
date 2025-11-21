#!/bin/bash

API_ID="16ayefk5lc"
REGION="us-east-1"

echo "Fixing CORS for b1 API Gateway..."

# Get all resources
RESOURCES=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[].id' --output text)

for RESOURCE_ID in $RESOURCES; do
    echo "Adding CORS to resource: $RESOURCE_ID"

    # Add OPTIONS method
    aws apigateway put-method \
      --rest-api-id $API_ID \
      --resource-id $RESOURCE_ID \
      --http-method OPTIONS \
      --authorization-type NONE \
      --region $REGION 2>/dev/null

    # Add method response
    aws apigateway put-method-response \
      --rest-api-id $API_ID \
      --resource-id $RESOURCE_ID \
      --http-method OPTIONS \
      --status-code 200 \
      --response-models '{"application/json":"Empty"}' \
      --response-parameters '{"method.response.header.Access-Control-Allow-Headers":false,"method.response.header.Access-Control-Allow-Methods":false,"method.response.header.Access-Control-Allow-Origin":false}' \
      --region $REGION 2>/dev/null

    # Add integration
    aws apigateway put-integration \
      --rest-api-id $API_ID \
      --resource-id $RESOURCE_ID \
      --http-method OPTIONS \
      --type MOCK \
      --request-templates '{"application/json":"{\"statusCode\":200}"}' \
      --region $REGION 2>/dev/null

    # Add integration response with wildcard origin
    aws apigateway put-integration-response \
      --rest-api-id $API_ID \
      --resource-id $RESOURCE_ID \
      --http-method OPTIONS \
      --status-code 200 \
      --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'","method.response.header.Access-Control-Allow-Methods":"'"'"'GET,POST,PUT,PATCH,DELETE,OPTIONS'"'"'","method.response.header.Access-Control-Allow-Origin":"'"'"'*'"'"'"}' \
      --region $REGION 2>/dev/null
done

# Deploy changes
echo "Deploying API changes..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "CORS fixed! API now accepts requests from all origins."