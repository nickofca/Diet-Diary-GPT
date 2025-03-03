output "api_endpoint" {
  description = "The URL of the API Gateway endpoint"
  value       = "${aws_api_gateway_deployment.diet_tracker_deployment.invoke_url}/prod/"
}