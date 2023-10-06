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
  function_name    = "vpn-client-authorizer"
  filename         = "${path.module}/authorize.zip"
  source_code_hash = fileexists("${path.module}/authorize.zip") ? filemd5("${path.module}/authorize.zip") : null
  role             = aws_iam_role.lambda_authorizer_role.arn
  handler          = "authorize"
  runtime          = "go1.x"

#   environment {
#     variables = {
#       EIP_ID         = var.eip_id
#       SENDER_EMAIL   = var.sender_email
#       REGION         = var.region
#       SES_REGION     = var.ses_region
#       RECEIVER_EMAIL = var.receiver_email
#     }
#   }

  tags = {
    Name = "vpn-client-authorizer"
  }
}

# resource "aws_iam_policy" "lambda_authorizer_policy" {
#   name        = "lambda_authorizer_policy"
#   description = "Allows to send back the authorization token to the api gateway"
  
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "lambda_authorizer_policy_attachment" {
  role       = aws_iam_role.lambda_authorizer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}