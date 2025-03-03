resource "aws_s3_bucket" "plugin_bucket" {
  bucket = var.plugin_bucket_name
  acl    = "public-read"

  website {
    index_document = "index.html"   # You can use a dummy index.html if desired
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "openapi" {
  bucket       = aws_s3_bucket.plugin_bucket.bucket
  key          = "openapi.yaml"
  source       = "${path.module}/../openapi.yaml"
  content_type = "text/yaml"
  acl          = "public-read"
}

resource "aws_s3_bucket_object" "plugin_manifest" {
  bucket       = aws_s3_bucket.plugin_bucket.bucket
  key          = "ai-plugin.json"
  source       = "${path.module}/../ai-plugin.json"
  content_type = "application/json"
  acl          = "public-read"
}