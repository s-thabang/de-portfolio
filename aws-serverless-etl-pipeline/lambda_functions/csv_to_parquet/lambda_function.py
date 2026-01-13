"""
Lambda function to convert Olist CSV files to Parquet format.

Triggered manually or via S3 event (future enhancement).
Reads CSV from raw bucket, transforms to Parquet, writes to processed bucket.
"""

import json
import boto3
import pandas as pd
import io
import os
from datetime import datetime

# Initialize AWS clients
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    Main Lambda handler function.
    
    Expected event format:
    {
        "raw_bucket": "olist-pipeline-raw-dev-065504275388",
        "processed_bucket": "olist-pipeline-processed-dev-065504275388",
        "file_key": "olist_orders_dataset.csv"
    }
    """
    
    try:
        # Extract parameters from event
        raw_bucket = event.get('raw_bucket')
        processed_bucket = event.get('processed_bucket')
        file_key = event.get('file_key')
        
        # Validation
        if not all([raw_bucket, processed_bucket, file_key]):
            raise ValueError("Missing required parameters: raw_bucket, processed_bucket, or file_key")
        
        print(f"Processing file: {file_key}")
        print(f"Source: s3://{raw_bucket}/{file_key}")
        
        # Step 1: Download CSV from S3 raw bucket
        print("Step 1: Downloading CSV from S3...")
        csv_obj = s3_client.get_object(Bucket=raw_bucket, Key=file_key)
        csv_content = csv_obj['Body'].read()
        
        # Step 2: Read CSV into pandas DataFrame
        print("Step 2: Reading CSV into pandas DataFrame...")
        df = pd.read_csv(io.BytesIO(csv_content))
        
        original_rows = len(df)
        original_size_mb = len(csv_content) / (1024 * 1024)
        
        print(f"  - Rows: {original_rows:,}")
        print(f"  - Columns: {len(df.columns)}")
        print(f"  - Original size: {original_size_mb:.2f} MB")
        print(f"  - Column names: {list(df.columns)}")
        
        # Step 3: Basic data quality checks
        print("Step 3: Running data quality checks...")
        null_counts = df.isnull().sum()
        if null_counts.sum() > 0:
            print(f"  ⚠️  Found null values:")
            for col, count in null_counts[null_counts > 0].items():
                print(f"    - {col}: {count} nulls ({count/len(df)*100:.1f}%)")
        else:
            print("  ✅ No null values found")
        
        # Step 4: Convert to Parquet
        print("Step 4: Converting to Parquet format...")
        parquet_buffer = io.BytesIO()
        df.to_parquet(
            parquet_buffer,
            engine='pyarrow',
            compression='snappy',  # Good balance of speed and compression
            index=False
        )
        parquet_content = parquet_buffer.getvalue()
        parquet_size_mb = len(parquet_content) / (1024 * 1024)
        
        compression_ratio = (1 - parquet_size_mb / original_size_mb) * 100
        print(f"  - Parquet size: {parquet_size_mb:.2f} MB")
        print(f"  - Compression: {compression_ratio:.1f}% reduction")
        
        # Step 5: Upload Parquet to processed bucket
        print("Step 5: Uploading Parquet to S3...")
        
        # Create output key (remove .csv, add .parquet, organize by table)
        base_name = file_key.replace('.csv', '')
        output_key = f"tables/{base_name}/{base_name}.parquet"
        
        s3_client.put_object(
            Bucket=processed_bucket,
            Key=output_key,
            Body=parquet_content,
            ContentType='application/octet-stream'
        )
        
        output_path = f"s3://{processed_bucket}/{output_key}"
        print(f"  ✅ Uploaded to: {output_path}")
        
        # Step 6: Return success response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully converted CSV to Parquet',
                'source_file': file_key,
                'output_path': output_path,
                'rows_processed': original_rows,
                'original_size_mb': round(original_size_mb, 2),
                'parquet_size_mb': round(parquet_size_mb, 2),
                'compression_ratio_percent': round(compression_ratio, 1),
                'timestamp': datetime.utcnow().isoformat()
            })
        }
        
        print("✅ Transformation completed successfully!")
        return response
        
    except Exception as e:
        print(f"❌ Error during transformation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'file_key': event.get('file_key', 'unknown')
            })
        }
