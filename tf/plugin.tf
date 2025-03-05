terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}
resource "aws_s3_bucket" "plugin_bucket" {
  bucket = var.plugin_bucket_name

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "openapi" {
  bucket       = aws_s3_bucket.plugin_bucket.bucket
  key          = "openapi.yaml"
  content      = templatefile("${path.module}/templates/openapi.tftpl", {
    api_id = aws_api_gateway_rest_api.diet_tracker_api.id
    region = var.region
  })
  content_type = "text/yaml"
}

resource "aws_s3_bucket_policy" "plugin_bucket_policy" {
  bucket = aws_s3_bucket.plugin_bucket.bucket

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.plugin_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "plugin_bucket_block" {
  bucket = aws_s3_bucket.plugin_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "local_file" "openapi" {
  content      = templatefile("${path.module}/templates/openapi.tftpl", {
    api_id = aws_api_gateway_rest_api.diet_tracker_api.id
    region = var.region
  })
  filename        = "${path.module}/../generated_resources/openapi.yaml"
}