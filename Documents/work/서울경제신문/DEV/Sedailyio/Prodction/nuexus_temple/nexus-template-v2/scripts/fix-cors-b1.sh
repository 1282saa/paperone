#!/bin/bash

API_ID="fulnhviof7"
REGION="us-east-1"
CLOUDFRONT_URL="https://d2puji5e0gzvv.cloudfront.net"

echo "🔧 Fixing CORS configuration for b1 API Gateway..."

# Update stage settings to enable CORS
aws apigateway update-stage \
  --rest-api-id $API_ID \
  --stage-name prod \
  --patch-operations \
    op=replace,path=/*/cors/allowOrigins,value="'$CLOUDFRONT_URL','http://localhost:5173','http://localhost:5174'" \
    op=replace,path=/*/cors/allowHeaders,value="'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'" \
    op=replace,path=/*/cors/allowMethods,value="'GET,POST,PUT,DELETE,OPTIONS'" \
  --region $REGION 2>/dev/null

# Get all resources
RESOURCES=$(aws apigateway get-resources --rest-api-id $API_ID --region $REGION --query 'items[].id' --output text)

echo "📝 Adding CORS to all resources..."
for RESOURCE_ID in $RESOURCES; do
    echo -n "  Resource $RESOURCE_ID: "
    
    # Check if OPTIONS method exists
    OPTIONS_EXISTS=$(aws apigateway get-method --rest-api-id $API_ID --resource-id $RESOURCE_ID --http-method OPTIONS --region $REGION 2>/dev/null)
    
    if [ -z "$OPTIONS_EXISTS" ]; then
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
        
        # Add integration response
        aws apigateway put-integration-response \
          --rest-api-id $API_ID \
          --resource-id $RESOURCE_ID \
          --http-method OPTIONS \
          --status-code 200 \
          --response-parameters '{"method.response.header.Access-Control-Allow-Headers":"'\''Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'\'''","method.response.header.Access-Control-Allow-Methods":"'\''GET,POST,PUT,DELETE,OPTIONS'\'''","method.response.header.Access-Control-Allow-Origin":"'\''*'\'''"}' \
          --region $REGION 2>/dev/null
        
        echo "✅ OPTIONS added"
    else
        # Update existing integration response to allow all origins
        aws apigateway update-integration-response \
          --rest-api-id $API_ID \
          --resource-id $RESOURCE_ID \
          --http-method OPTIONS \
          --status-code 200 \
          --patch-operations \
            op=replace,path=/responseParameters/method.response.header.Access-Control-Allow-Origin,value="'*'" \
          --region $REGION 2>/dev/null
        echo "✅ OPTIONS updated"
    fi
done

# Deploy the changes
echo "🚀 Deploying API changes..."
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region $REGION

echo "✅ CORS configuration fixed!"
echo "📌 API Gateway now allows requests from:"
echo "   - $CLOUDFRONT_URL"
echo "   - http://localhost:5173"
echo "   - http://localhost:5174"
echo "   - All origins for OPTIONS requests"