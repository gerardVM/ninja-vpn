resource "aws_iam_role" "lambda_authorizer_role" {
  name = "vpn-client-authorizer"
  
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

resource "aws_lambda_function" "authorizer" {
  function_name    = "ninja-vpn-client-authorizer"
  filename         = "${path.module}/authorize.zip"
  source_code_hash = fileexists("${path.module}/authorize.zip") ? filebase64sha256("${path.module}/authorize.zip") : null
  role             = aws_iam_role.lambda_authorizer_role.arn
  handler          = "authorize"
  runtime          = "go1.x"

  environment {
    variables = {
      SSM_SECRET_NAME = var.ssm_secret_name
    }
  }

  tags = {
    Name = "vpn-client-authorizer"
  }
}

resource "aws_iam_policy" "ninja_vpn_authorizer_policy" {
  name        = "ninja-vpn-authorizer-policy"
  description = "Allows Lambda to get the authorization header value from Secrets Manager"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameterHistory"
        ]
        Resource = var.ssm_secret_arn
      },
      {
        Effect = "Allow"
        Action = [    
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_role.name
  policy_arn = aws_iam_policy.ninja_vpn_authorizer_policy.arn
}