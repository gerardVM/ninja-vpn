resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  
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
  filename         = "${path.module}/terminate_instance.zip"
  function_name    = "terminate_instance"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "terminate_instance.lambda_handler"
  runtime          = "python3.8"
  timeout          = 10
  memory_size      = 128

  tags = var.tags
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/terminate_instance.py"
  output_path = "${path.module}/terminate_instance.zip"
}

resource "aws_lambda_permission" "allow_cloudwatch_events" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terminate_instance_lambda.function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.terminate_instance_rule.arn
}

resource "aws_iam_policy" "termination_policy" {
  name        = "cloudwatch_policy"
  description = "Allows Lambda to delete a CloudWatch event rule and terminate an EC2 instance"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:RemoveTargets",
          "events:ListTargetsByRule",
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

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  policy_arn = aws_iam_policy.termination_policy.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_cloudwatch_event_rule" "terminate_instance_rule" {
  name                = "terminate_instance_rule"
  schedule_expression = "rate(${var.countdown})"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "terminate_instance_target" {
  rule      = aws_cloudwatch_event_rule.terminate_instance_rule.name
  arn       = aws_lambda_function.terminate_instance_lambda.arn
  input     = jsonencode({
    "instance_id": var.instance_id,
    "eip_id": var.eip_id,
    "rule_id": aws_cloudwatch_event_rule.terminate_instance_rule.id,
    "email_address": var.email
  })
}