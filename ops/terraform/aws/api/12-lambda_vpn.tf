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
  function_name    = "ninja-vpn-controller"
  filename         = "${path.root}/launch_vpn.zip"
  source_code_hash = fileexists("${path.root}/launch_vpn.zip") ? filebase64sha256("${path.root}/launch_vpn.zip") : null
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "launch_vpn"
  runtime          = "go1.x"
  timeout          = 600
  memory_size      = 2560
  ephemeral_storage {
    size = 9216
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
        Sid = "EC2andIAMPermissions"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "iam:*"
        ]
        Resource = "*"
      },
      {
        Sid = "LambdaPermissions"
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:ninja-vpn-*"
      },
      {
        Sid = "S3Permissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging"
        ]
        Resource = "arn:aws:s3:::ninja-vpn-*"
      },
      {
        Sid = "DecryptKMS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = "*"
      },
      {
        Sid = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.state_locker.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "launch_vpn" {
  policy_arn = aws_iam_policy.vpn_controller.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}