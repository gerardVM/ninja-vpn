output endpoint {
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_resource.resource.path}"
  description = "Information about the api gateway"
  depends_on  = [aws_api_gateway_deployment.deployment, aws_api_gateway_resource.resource]
}
