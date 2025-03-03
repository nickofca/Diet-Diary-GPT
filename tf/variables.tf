variable "namespace" {
  description = "A namespace to prefix resource names"
  type        = string
  default     = "default"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "plugin_bucket_name" {
  description = "The name of the S3 bucket to host the ChatGPT plugin manifest and OpenAPI spec"
  type        = string
  default     = "my-diettracker-plugin-bucket"  # must be globally unique!
}