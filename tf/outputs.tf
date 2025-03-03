output "api_endpoint" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_deployment.diet_tracker_deployment.invoke_url}/prod/"
}

output "plugin_manifest_url" {
  description = "Public URL for the ChatGPT plugin manifest"
  value       = "http://${aws_s3_bucket.plugin_bucket.website_endpoint}/ai-plugin.json"
}

output "openapi_url" {
  description = "Public URL for the OpenAPI specification"
  value       = "http://${aws_s3_bucket.plugin_bucket.website_endpoint}/openapi.yaml"
}