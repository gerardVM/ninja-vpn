resource "aws_iam_role" "header_rotation_role" {
  name = "ninja-vpn-header-rotation-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
      }
    ]
  })
}

data "archive_file" "injector" {
  type        = "zip"
  source_file = "${path.module}/header_rotation.py"
  output_path = "${path.module}/header_rotation.zip"
}

resource "aws_lambda_function" "header_rotation" {
  function_name    = "ninja-vpn-header-rotation"
  filename         = "${path.module}/header_rotation.zip"
  source_code_hash = fileexists("${path.module}/header_rotation.zip") ? filemd5("${path.module}/header_rotation.zip") : null
  role             = aws_iam_role.header_rotation_role.arn
  handler          = "header_rotation.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      SSM_PARAMETER_NAME                = aws_ssm_parameter.ninja-vpn-authorization-header-value.name
      CLOUDFRONT_DISTRIBUTION_ID        = var.cloudfront_distribution_id
      CLOUDFRONT_ORIGIN_ID              = var.cloudfront_origin_id
      CLOUDFRONT_AUTHORIZER_HEADER_NAME = var.cloudfront_authorizer_header_name
    }
  }

  tags = {
    Name = "ninja-vpn"
  }
}

resource "aws_iam_policy" "header_rotation_policy" {
  name        = "ninja-vpn-header-rotation-policy"
  description = "Allows Lambda to rotate the header"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = aws_ssm_parameter.ninja-vpn-authorization-header-value.arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:GetDistribution",
          "cloudfront:UpdateDistribution"
        ]
        Resource = var.cloudfront_distribution_arn
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

resource "aws_iam_role_policy_attachment" "header_rotation_policy_attachment" {
  role       = aws_iam_role.header_rotation_role.name
  policy_arn = aws_iam_policy.header_rotation_policy.arn
}