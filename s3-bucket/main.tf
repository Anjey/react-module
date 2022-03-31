terraform {
  required_version = ">= 1.0.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56.0"
    }
  }
}

locals {
  names = {
    bucket1 = var.buckets1
    bucket2 = var.buckets2
  }
  buckets = { for k, v in local.names : k =>
    {
      id = v.id
    web_site = v.bucket_regional_domain_name }
  }
}

resource "aws_s3_bucket" "deploy_bucket" {
  bucket = var.domain_name_www
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.deploy_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.deploy_bucket.arn}/*"
      },
    ]
  })
}
