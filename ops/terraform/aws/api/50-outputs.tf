output endpoint {
  value       = "${aws_apigatewayv2_api.api.execution_arn}/staging/lambda"
  description = "Information about the api gateway"
}
