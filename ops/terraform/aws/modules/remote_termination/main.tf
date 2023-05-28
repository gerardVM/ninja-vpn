resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role-${var.suffix}"
  
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

resource "aws_lambda_function" "terminate_instance_lambda" {
  function_name    = "${var.function_name}-${var.suffix}"
  filename         = "${path.module}/terminate_instance.zip"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "terminate_instance.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      INSTANCE_ID    = var.instance_id
      EIP_ID         = var.eip_id
      SENDER_EMAIL   = var.sender_email
      SENDER_REGION  = var.sender_region
      RECEIVER_EMAIL = var.receiver_email
    }
  }

  tags = var.tags
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/terminate_instance.py"
  output_path = "${path.module}/terminate_instance.zip"
}

resource "aws_iam_policy" "termination_policy" {
  name        = "cloudwatch_policy-${var.suffix}"
  description = "Allows Lambda to delete a CloudWatch event rule and terminate an EC2 instance"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:TerminateInstances",
          "ec2:ReleaseAddress",
          "ses:SendEmail",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "termination_policy_attachment" {
  policy_arn = aws_iam_policy.termination_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}