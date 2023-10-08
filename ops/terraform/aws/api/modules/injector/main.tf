provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_injector_role" {
  name = "ninja-vpn-header-injector"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
        }
      }
    ]
  })
}

data "archive_file" "injector" {
  type        = "zip"
  source_file = "${path.module}/injector.js"
  output_path = "${path.module}/injector.zip"
}

resource "aws_lambda_function" "injector" {
  function_name    = "ninja-vpn-header-injector"
  filename         = "${path.module}/injector.zip"
  source_code_hash = fileexists("${path.module}/injector.zip") ? filemd5("${path.module}/injector.zip") : null
  role             = aws_iam_role.lambda_injector_role.arn
  handler          = "injector.handler"
  runtime          = "nodejs18.x"
  # timeout          = 10
  publish          = true

  tags = {
    Name = "ninja-vpn"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_injector_policy_attachment" {
  role       = aws_iam_role.lambda_injector_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}