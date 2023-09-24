resource "aws_api_gateway_rest_api" "api" {
  name = "ninja-vpn-api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "lambda"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.vpn_controller.invoke_arn
  request_parameters = {
    "integration.request.header.X-Amz-Invocation-Type" = "'Event'" # async -> 502 Bad Gateway but still works
  }
  request_templates = {
    "application/json" = jsonencode({  # Assuming the Lambda expects JSON data
      "body" = "$input.body"          # Pass the entire request body to the Lambda
    })
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "launch"
}