resource "aws_s3_bucket" "plugin_bucket" {
  bucket = var.plugin_bucket_name

  website {
    index_document = "index.html"   # You can supply a dummy index.html if desired
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "openapi" {
  bucket       = aws_s3_bucket.plugin_bucket.bucket
  key          = "openapi.yaml"
  source       = "${path.module}/../openapi.yaml"
  content_type = "text/yaml"
  # acl removed
}

resource "aws_s3_bucket_object" "plugin_manifest" {
  bucket       = aws_s3_bucket.plugin_bucket.bucket
  key          = "ai-plugin.json"
  source       = "${path.module}/../ai-plugin.json"
  content_type = "application/json"
  # acl removed
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