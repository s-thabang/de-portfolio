# Script to upload Olist CSV files to S3 raw bucket

set -e

echo "Starting data upload to S3..."

# Get bucket name from Terraform
cd ../terraform
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
cd ../scripts

echo "Target bucket: $RAW_BUCKET"
echo ""

# Upload all CSV files
CSV_DIR="../data/raw"
CSV_COUNT=$(ls $CSV_DIR/*.csv 2>/dev/null | wc -l | tr -d ' ')

if [ $CSV_COUNT -eq 0 ]; then
    echo "No CSV files found in $CSV_DIR"
    exit 1
fi

echo "Found $CSV_COUNT CSV files to upload"
echo ""

for csv_file in $CSV_DIR/*.csv; do
    filename=$(basename "$csv_file")
    echo "⬆  Uploading: $filename"
    
    aws s3 cp "$csv_file" "s3://$RAW_BUCKET/$filename" --region af-south-1
    
    # Get file size
    size=$(du -h "$csv_file" | cut -f1)
    echo "   Uploaded ($size)"
    echo ""
done

echo " All files uploaded successfully!"
echo ""
echo "Verify with: aws s3 ls s3://$RAW_BUCKET/ --region af-south-1"
