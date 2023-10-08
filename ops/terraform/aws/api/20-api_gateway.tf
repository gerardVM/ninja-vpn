resource "aws_apigatewayv2_api" "api" {
  name          = "ninja-vpn-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["POST"]
    # allow_origins = ["https://${aws_cloudfront_distribution.distribution.domain_name}", "https://${aws_route53_record.root_domain.name}"]
    # allow_origins = ["https://${aws_route53_record.root_domain.name}"]
    allow_origins = ["*"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.vpn_controller_trigger.invoke_arn
  passthrough_behavior   = "WHEN_NO_MATCH"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "POST /lambda"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer.id
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "staging"
  auto_deploy = true
  route_settings {
    route_key = aws_apigatewayv2_route.lambda.route_key
    detailed_metrics_enabled = false
    throttling_burst_limit = 1
    throttling_rate_limit = 1
  }
}

resource "aws_apigatewayv2_deployment" "lambda" {
  api_id      = aws_apigatewayv2_api.api.id
  description = "Deployment for Lambda"

  depends_on = [aws_apigatewayv2_route.lambda]
}