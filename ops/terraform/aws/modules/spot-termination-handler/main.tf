data "aws_region" "current" {}

variable "user_data" {
  type = string
  default = <<-EOF
              #!/bin/bash

              # Set up a termination notice handler
              /usr/bin/aws sns subscribe --topic-arn ${aws_sns_topic.termination_notice_topic.arn} \
                  --protocol https \
                  --notification-endpoint "https://${data.aws_region.current.name}.endpoint.com"

              # Start your application
              # /usr/local/bin/start-my-app
              EOF
}

resource "aws_sns_topic" "termination_notice_topic" {
  name = "spot-termination-notices"
}

resource "aws_iam_role" "termination_notice_role" {
  name = "spot-termination-notices"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "termination_notice_policy" {
  name = "spot-termination-notices"
  role = aws_iam_role.termination_notice_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = [
          aws_sns_topic.termination_notice_topic.arn,
        ]
      },
    ]
  })
}


resource "aws_sns_topic_subscription" "termination_notice_subscription" {
  topic_arn = aws_sns_topic.termination_notice_topic.arn
#   protocol  = "lambda"
#   endpoint  = aws_lambda_function.termination_notice_lambda.arn
  protocol  = "email"
  endpoint  = "valverdegerard@gmail.com"
}

resource "aws_api_gateway_rest_api" "termination_notice_api" {
  name = "spot-termination-notices"
}

resource "aws_api_gateway_resource" "termination_notice_resource" {
  rest_api_id = aws_api_gateway_rest_api.termination_notice_api.id
  parent_id   = aws_api_gateway_rest_api.termination_notice_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "termination_notice_method" {
  rest_api_id = aws_api_gateway_rest_api.termination_notice_api.id
  resource_id = aws_api_gateway_resource.termination_notice_resource.id
  http_method = "POST"
}

resource "aws_api_gateway_integration" "termination_notice_integration" {
  rest_api_id             = aws_api_gateway_rest_api.termination_notice_api.id
  resource_id             = aws_api_gateway_resource.termination_notice_resource.id
  http_method             = aws_api_gateway_method.termination_notice_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.termination_notice_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "termination_notice_deployment" {
  depends_on  = [aws_api_gateway_integration.termination_notice_integration]
  rest_api_id = aws_api_gateway_rest_api.termination_notice_api.id
  stage_name  = "default"
}