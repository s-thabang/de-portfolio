
cd ../terraform
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
PROCESSED_BUCKET=$(terraform output -raw processed_bucket_name)
cd ../scripts

echo "Testing Lambda with product_category_name_translation.csv (smallest file)..."
echo ""

aws lambda invoke \
    --function-name olist-pipeline-transform \
    --payload "{\"raw_bucket\":\"$RAW_BUCKET\",\"processed_bucket\":\"$PROCESSED_BUCKET\",\"file_key\":\"product_category_name_translation.csv\"}" \
    --region af-south-1 \
    --cli-binary-format raw-in-base64-out \
    /tmp/test_response.json

echo ""
echo "Response:"
cat /tmp/test_response.json | python3 -m json.tool
