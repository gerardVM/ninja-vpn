resource "aws_api_gateway_rest_api" "api" {
  name = "ninja-vpn-api"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "{cors+}"
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  # http_method   = "POST"
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true,
  }
  
  depends_on = [aws_api_gateway_method.method]
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
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

resource "aws_api_gateway_integration" "cors" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "OPTIONS"
  type                    = "MOCK"
  request_templates = {
    "application/json" = jsonencode({  # Assuming the Lambda expects JSON data
      "statusCode" = "200"          # Pass the entire request body to the Lambda
    })
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.cors.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'", # Change
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "staging"
}

# resource "aws_api_gateway_deployment" "cors" {
#   depends_on = [aws_api_gateway_integration.cors]
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   stage_name  = "staging"
# }

resource "aws_api_gateway_gateway_response" "response_4xx" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_4XX"
  status_code   = "404"
  response_templates = {
    "application/json" = jsonencode({  # Change for something more professional
      "message" = "Not Found"          
    })
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'", # Change
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'POST'",
  }
}

resource "aws_api_gateway_gateway_response" "response_5xx" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  response_type = "DEFAULT_5XX"
  status_code   = "500"
  response_templates = {
    "application/json" = jsonencode({  # Change for something more professional
      "message" = "Internal Server Error"          
    })
  }
  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'", # Change
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type'",
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'POST'",
  }
}