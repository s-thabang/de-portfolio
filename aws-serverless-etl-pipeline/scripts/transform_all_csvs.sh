# Script to invoke Lambda function for all CSV files

set -e

echo "Starting CSV to Parquet transformation..."

# Get bucket names from Terraform
cd ../terraform
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
PROCESSED_BUCKET=$(terraform output -raw processed_bucket_name)
cd ../scripts

FUNCTION_NAME="olist-pipeline-transform"
REGION="af-south-1"

echo "Configuration:"
echo "   Raw bucket: $RAW_BUCKET"
echo "   Processed bucket: $PROCESSED_BUCKET"
echo "   Lambda function: $FUNCTION_NAME"
echo ""

# List of CSV files to process
CSV_FILES=(
    "olist_customers_dataset.csv"
    "olist_geolocation_dataset.csv"
    "olist_order_items_dataset.csv"
    "olist_order_payments_dataset.csv"
    "olist_order_reviews_dataset.csv"
    "olist_orders_dataset.csv"
    "olist_products_dataset.csv"
    "olist_sellers_dataset.csv"
    "product_category_name_translation.csv"
)

total=${#CSV_FILES[@]}
current=0

for csv_file in "${CSV_FILES[@]}"; do
    ((current++))
    echo "[$current/$total] Processing: $csv_file"
    
    # Create event payload
    payload=$(cat <<EOF_JSON
{
    "raw_bucket": "$RAW_BUCKET",
    "processed_bucket": "$PROCESSED_BUCKET",
    "file_key": "$csv_file"
}
EOF_JSON
)
    
    # Invoke Lambda function
    response=$(aws lambda invoke \
        --function-name $FUNCTION_NAME \
        --payload "$payload" \
        --region $REGION \
        --cli-binary-format raw-in-base64-out \
        /tmp/lambda_response_$current.json 2>&1)
    
    # Check for errors
    if echo "$response" | grep -q "StatusCode.*200"; then
        # Parse response
        result=$(cat /tmp/lambda_response_$current.json | python3 -c "import sys, json; data=json.load(sys.stdin); body=json.loads(data['body']); print(f\"✅ {body['rows_processed']:,} rows | {body['original_size_mb']} MB → {body['parquet_size_mb']} MB ({body['compression_ratio_percent']}% compression)\")" 2>/dev/null || echo "✅ Success")
        echo "   $result"
    else
        echo "   Error invoking Lambda"
        cat /tmp/lambda_response_$current.json
    fi
    
    echo ""
done

echo "All transformations complete!"
echo ""
echo "Next steps:"
echo "1. Run Glue Crawler to catalog the data"
echo "2. Query with Athena"
