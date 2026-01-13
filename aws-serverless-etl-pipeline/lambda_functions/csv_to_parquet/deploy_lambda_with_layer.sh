#!/bin/bash

# Lambda deployment script using AWS Data Wrangler Layer
# No need to package pandas/pyarrow - uses pre-built layer!

set -e

echo "🚀 Starting Lambda deployment (using AWS Data Wrangler Layer)..."

# Configuration
FUNCTION_NAME="olist-pipeline-transform"
REGION="af-south-1"
RUNTIME="python3.11"
HANDLER="lambda_function.lambda_handler"
TIMEOUT=300
MEMORY=512

# AWS Data Wrangler Layer ARN for af-south-1, Python 3.11
# This layer includes: pandas, pyarrow, numpy, and many other data libraries
LAYER_ARN="arn:aws:lambda:af-south-1:336392948345:layer:AWSSDKPandas-Python311:18"

# Get Lambda role ARN from Terraform
cd ../../terraform
ROLE_ARN=$(terraform output -raw lambda_role_arn)
cd ../lambda_functions/csv_to_parquet

echo "✅ Lambda role ARN: $ROLE_ARN"
echo "✅ Using AWS Data Wrangler Layer (includes pandas + pyarrow)"

# Create simple package (just our code, no dependencies)
echo "📦 Creating deployment package..."
rm -rf package
mkdir -p package

# Copy only Lambda function code
cp lambda_function.py package/

# Create ZIP file
cd package
zip -r ../lambda_deployment.zip . -q
cd ..

echo "📊 Package size: $(du -h lambda_deployment.zip | cut -f1)"

# Check if Lambda function exists
echo "🔍 Checking if Lambda function exists..."
if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION >/dev/null 2>&1; then
    echo "♻️  Updating existing Lambda function..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://lambda_deployment.zip \
        --region $REGION \
        --output json > /dev/null
    
    echo "⚙️  Updating function configuration..."
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --timeout $TIMEOUT \
        --memory-size $MEMORY \
        --layers "$LAYER_ARN" \
        --region $REGION \
        --output json > /dev/null
else
    echo "🆕 Creating new Lambda function..."
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime $RUNTIME \
        --role $ROLE_ARN \
        --handler $HANDLER \
        --zip-file fileb://lambda_deployment.zip \
        --timeout $TIMEOUT \
        --memory-size $MEMORY \
        --layers "$LAYER_ARN" \
        --region $REGION \
        --description "Converts Olist CSV files to Parquet format" \
        --output json > /dev/null
fi

echo "✅ Lambda function deployed successfully!"
echo ""
echo "Function details:"
echo "  Name: $FUNCTION_NAME"
echo "  Runtime: $RUNTIME"
echo "  Memory: ${MEMORY}MB"
echo "  Timeout: ${TIMEOUT}s"
echo "  Region: $REGION"
echo "  Layer: AWS Data Wrangler (pandas, pyarrow, numpy)"

# Cleanup
echo "🧹 Cleaning up..."
rm -rf package
rm lambda_deployment.zip

echo ""
echo "✅ Deployment complete!"
