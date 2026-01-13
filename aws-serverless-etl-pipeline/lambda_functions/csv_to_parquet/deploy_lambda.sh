#!/bin/bash

# Lambda deployment script using Docker for compatibility
# Ensures packages work on AWS Lambda (x86_64 Linux)

set -e  # Exit on any error

echo "🚀 Starting Lambda deployment process (Docker method)..."

# Configuration
FUNCTION_NAME="olist-pipeline-transform"
REGION="af-south-1"
RUNTIME="python3.11"
HANDLER="lambda_function.lambda_handler"
TIMEOUT=300  # 5 minutes
MEMORY=512   # 512 MB

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

# Get Lambda role ARN from Terraform outputs
cd ../../terraform
ROLE_ARN=$(terraform output -raw lambda_role_arn)
cd ../lambda_functions/csv_to_parquet

echo "✅ Lambda role ARN: $ROLE_ARN"
echo "✅ Docker is running"

# Build Docker image with dependencies
echo "🐳 Building Docker image with Lambda dependencies..."
docker build -t lambda-builder:latest . --platform linux/amd64

# Create package directory
echo "📦 Extracting deployment package from Docker..."
rm -rf package
mkdir -p package

# Run container and copy files out
docker create --name lambda-temp lambda-builder:latest
docker cp lambda-temp:/asset/. ./package/
docker rm lambda-temp

# Create ZIP file
echo "🗜️  Creating ZIP archive..."
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
        --region $REGION
    
    echo "⚙️  Updating function configuration..."
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --timeout $TIMEOUT \
        --memory-size $MEMORY \
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

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -rf package
rm lambda_deployment.zip
docker rmi lambda-builder:latest > /dev/null 2>&1

echo ""
echo "✅ Deployment complete!"
