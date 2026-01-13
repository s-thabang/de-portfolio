# Terraform configuration for Olist Serverless Data Pipeline
# Architecture: S3 + Lambda + Glue + Athena

# ============================================
# PROVIDER & DATA SOURCES
# ============================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}

# ============================================
# S3 BUCKETS
# ============================================

# Raw data bucket (receives uploaded CSVs)
resource "aws_s3_bucket" "raw" {
  bucket = local.raw_bucket_name
  
  # Prevent accidental deletion during terraform destroy
  force_destroy = true  # Change to false in production!
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "raw" {
  bucket = aws_s3_bucket.raw.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning (free within limits, good practice)
resource "aws_s3_bucket_versioning" "raw" {
  bucket = aws_s3_bucket.raw.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Processed data bucket (receives Parquet files from Lambda)
resource "aws_s3_bucket" "processed" {
  bucket = local.processed_bucket_name
  
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket = aws_s3_bucket.processed.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================
# IAM ROLE FOR LAMBDA
# ============================================

# Trust policy: Allow Lambda service to assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attach AWS managed policy for basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy: Allow Lambda to read from raw bucket and write to processed bucket
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    
    resources = [
      aws_s3_bucket.raw.arn,
      "${aws_s3_bucket.raw.arn}/*"
    ]
  }
  
  statement {
    effect = "Allow"
    
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    
    resources = [
      "${aws_s3_bucket.processed.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3" {
  name   = "${var.project_name}-lambda-s3-policy"
  policy = data.aws_iam_policy_document.lambda_s3_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3.id
}

# ============================================
# GLUE DATA CATALOG
# ============================================

# Glue database (logical container for tables)
resource "aws_glue_catalog_database" "olist" {
  name        = "${var.project_name}_db"
  description = "Data catalog for Olist e-commerce analytics"
}

# IAM role for Glue Crawler
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_crawler" {
  name               = "${var.project_name}-glue-crawler-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

# Attach AWS managed policy for Glue service
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy: Allow Glue to read processed bucket
data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    
    resources = [
      aws_s3_bucket.processed.arn,
      "${aws_s3_bucket.processed.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "glue_s3" {
  name   = "${var.project_name}-glue-s3-policy"
  policy = data.aws_iam_policy_document.glue_s3_access.json
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = aws_iam_policy.glue_s3.id
}

# Glue Crawler (discovers schema of Parquet files)
resource "aws_glue_crawler" "processed_data" {
  name          = "${var.project_name}-crawler"
  database_name = aws_glue_catalog_database.olist.name
  role          = aws_iam_role.glue_crawler.arn
  
  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}/"
  }
  
  # Run on-demand (not scheduled - saves costs)
  schedule = null
  
  # Configuration for Parquet files
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
}

# ============================================
# ATHENA WORKGROUP
# ============================================

# S3 bucket for Athena query results
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project_name}-athena-results-${data.aws_caller_identity.current.account_id}"
  
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rule: Delete query results after 7 days (cost savings)
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  
  rule {
    id     = "delete-old-results"
    status = "Enabled"
    
    filter {
      prefix = "results/"
    }
    
    expiration {
      days = 7
    }
  }
}

# Athena workgroup
resource "aws_athena_workgroup" "olist" {
  name        = "${var.project_name}-workgroup"
  description = "Workgroup for Olist analytics queries"
  
  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false  # Disable to save costs
    
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }
}

# ============================================
# CLOUDWATCH LOG GROUP (for Lambda logs)
# ============================================

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-transform"
  retention_in_days = 7  # Free tier: 5GB storage, 7 days is reasonable
}
