# Terraform outputs - displayed after apply

output "raw_bucket_name" {
  description = "S3 bucket for raw CSV uploads"
  value       = aws_s3_bucket.raw.id
}

output "processed_bucket_name" {
  description = "S3 bucket for processed Parquet files"
  value       = aws_s3_bucket.processed.id
}

output "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.id
}

output "glue_database_name" {
  description = "Glue database name for Athena queries"
  value       = aws_glue_catalog_database.olist.name
}

output "glue_crawler_name" {
  description = "Glue crawler name (run after uploading data)"
  value       = aws_glue_crawler.processed_data.name
}

output "athena_workgroup_name" {
  description = "Athena workgroup for running queries"
  value       = aws_athena_workgroup.olist.name
}

output "lambda_role_arn" {
  description = "IAM role ARN for Lambda function"
  value       = aws_iam_role.lambda_exec.arn
}

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
  
  Infrastructure deployed successfully!
  
  Next steps:
  1. Upload CSV files to: ${aws_s3_bucket.raw.id}
  2. Create Lambda function for transformation
  3. Run Glue Crawler: ${aws_glue_crawler.processed_data.name}
  4. Query data with Athena in workgroup: ${aws_athena_workgroup.olist.name}
  
  EOT
}
