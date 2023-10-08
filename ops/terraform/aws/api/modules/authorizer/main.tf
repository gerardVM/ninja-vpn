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
  source_code_hash = fileexists("${path.module}/authorize.zip") ? filemd5("${path.module}/authorize.zip") : null
  role             = aws_iam_role.lambda_authorizer_role.arn
  handler          = "authorize"
  runtime          = "go1.x"

  tags = {
    Name = "vpn-client-authorizer"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_authorizer_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}