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
  timeout          = 180
  memory_size      = 128

  environment {
    variables = {
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