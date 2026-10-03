output "api_url" {
  description = "Base URL of the API. POST questions to <api_url>/ask."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "test_command" {
  description = "Runs the test suite against this deployment (from the repo root, in PowerShell)."
  value       = "powershell -ExecutionPolicy Bypass -File .\\tests\\run-tests.ps1 -Url ${trimsuffix(aws_apigatewayv2_stage.default.invoke_url, "/")}"
}

output "faq_bucket" {
  value = aws_s3_bucket.faq.id
}

output "guardrail" {
  value = "${aws_bedrock_guardrail.this.guardrail_id} (version ${aws_bedrock_guardrail_version.this.version})"
}
