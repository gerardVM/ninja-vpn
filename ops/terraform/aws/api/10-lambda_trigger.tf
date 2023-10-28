resource "aws_iam_role" "lambda_trigger_role" {
  name = "vpn-controller-trigger-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "vpn_controller_trigger" {
  function_name    = "ninja-vpn-controller-trigger"
  filename         = "${path.root}/trigger_lambda.zip"
  source_code_hash = fileexists("${path.root}/trigger_lambda.zip") ? filebase64sha256("${path.root}/trigger_lambda.zip") : null
  role             = aws_iam_role.lambda_trigger_role.arn
  handler          = "trigger_lambda"
  runtime          = "go1.x"

  environment {
    variables = {
      API_REGION   = local.config.api_region
      DYNAMODB_TABLE  = aws_dynamodb_table.authorized_users.name
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "vpn_controller_trigger" {
  name        = "vpn-controller-trigger"
  description = "Allows Lambda to depoy all necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.vpn_controller.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.authorized_users.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "trigger_vpn" {
  policy_arn = aws_iam_policy.vpn_controller_trigger.arn
  role       = aws_iam_role.lambda_trigger_role.name
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpn_controller_trigger.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.api_region}:${local.api_accountId}:${aws_apigatewayv2_api.api.id}/*"
}