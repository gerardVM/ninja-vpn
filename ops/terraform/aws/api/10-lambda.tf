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
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      # EIP_ID         = var.eip_id
      # SENDER_EMAIL   = var.sender_email
      # SES_REGION     = var.ses_region
      # RECEIVER_EMAIL = var.receiver_email
      SENDER_EMAIL     ="valverdegerard+sender@gmail.com"
      EMAIL            ="valverdegerard@gmail.com"
      ACTION           ="deploy"
      TIMEZONE         ="Europe/Madrid"
      COUNTDOWN        ="5 minutes"
      REGION           ="eu-west-3" 
    }
  }

  tags = local.tags
}

# data "archive_file" "lambda_function" {
#   type        = "zip"
#   source_file = "${path.module}/launch_vpn"
#   output_path = "${path.module}/launch_vpn.zip"
# }

resource "aws_iam_policy" "vpn_controller" {
  name        = "vpn-controller"
  description = "Allows Lambda to delete a CloudWatch event rule and terminate an EC2 instance"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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

resource "aws_iam_role_policy_attachment" "termination_policy_attachment" {
  policy_arn = aws_iam_policy.vpn_controller.arn
  role       = aws_iam_role.lambda_execution_role.name
}