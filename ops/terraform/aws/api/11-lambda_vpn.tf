resource "aws_iam_role" "lambda_execution_role" {
  name = "vpn-controller-lambda"
  
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

resource "aws_lambda_function" "vpn_controller" {
  function_name    = "vpn-controller"
  filename         = "${path.module}/launch_vpn.zip"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "launch_vpn"
  runtime          = "go1.x"
  timeout          = 600
  memory_size      = 2560
  ephemeral_storage {
    size = 9216
  }

  environment {
    variables = {
      SENDER_EMAIL   = local.config.ses_sender_email
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "vpn_controller" {
  name        = "vpn-controller"
  description = "Allows Lambda to depoy all necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "s3:*",
          "ses:*",
          "lambda:*",
          "iam:*",
          "kms:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "launch_vpn" {
  policy_arn = aws_iam_policy.vpn_controller.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_permission" "allow_trigger_lambda" {
  statement_id  = "AllowExecutionFromLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vpn_controller.function_name
  principal     = "lambda.amazonaws.com"
  source_arn    = aws_lambda_function.vpn_controller_trigger.arn
}