# Project-wide variables for Olist Data Pipeline

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "af-south-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "olist-pipeline"
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "your_name" {
  description = "Your name for tagging resources (helps identify in AWS console)"
  type        = string
  default     = "thabang"
}

# Computed locals (don't change these)
locals {
  raw_bucket_name       = "${var.project_name}-raw-${var.environment}-${data.aws_caller_identity.current.account_id}"
  processed_bucket_name = "${var.project_name}-processed-${var.environment}-${data.aws_caller_identity.current.account_id}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.your_name
  }
}
