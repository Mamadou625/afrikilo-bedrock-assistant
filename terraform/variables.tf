variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource names."
  type        = string
  default     = "afrikilo-assistant"
}

variable "model_id" {
  description = "Bedrock inference profile ID used by the Converse API."
  type        = string
  default     = "us.amazon.nova-2-lite-v1:0"
}

variable "api_throttle_rate" {
  description = "Steady-state requests per second allowed by API Gateway."
  type        = number
  default     = 5
}

variable "api_throttle_burst" {
  description = "Burst of requests allowed by API Gateway."
  type        = number
  default     = 10
}

variable "cors_allowed_origins" {
  description = "Origins allowed to call the API from a browser."
  type        = list(string)
  default     = ["*"]
}

variable "log_retention_days" {
  description = "CloudWatch log retention for the Lambda function."
  type        = number
  default     = 7
}

variable "grounding_threshold" {
  description = "Contextual grounding threshold (0-0.99). Answers scoring lower are blocked."
  type        = number
  default     = 0.5
}
