module "authorization" {
  source = "./modules/authorizer"

  ssm_secret_arn  = module.header_rotation.parameter_arn
  ssm_secret_name = module.header_rotation.parameter_name
}

module "header_rotation" {
  source = "./modules/header_rotation"

  cloudfront_distribution_arn       = aws_cloudfront_distribution.distribution.arn
  cloudfront_distribution_id        = aws_cloudfront_distribution.distribution.id
  cloudfront_origin_id              = "${aws_apigatewayv2_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
  cloudfront_authorizer_header_name = "x-origin-verify"
}

resource "aws_iam_role" "authorizer_lambda_trigger_role" {
  name = "authorizer_lambda_trigger_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "authorizer_lambda_trigger_policy" {
  name        = "authorizer_lambda_trigger_policy"
  description = "Allows Lambda to depoy all necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
    })
}

resource "aws_iam_role_policy_attachment" "authorizer_lambda_trigger_role_policy" {
  role       = aws_iam_role.authorizer_lambda_trigger_role.name
  policy_arn = aws_iam_policy.authorizer_lambda_trigger_policy.arn
}

resource "aws_apigatewayv2_authorizer" "api_authorizer" {
    name                              = "api_authorizer"
    api_id                            = aws_apigatewayv2_api.api.id
    authorizer_type                   = "REQUEST"
    authorizer_uri                    = module.authorization.authorizer_uri
    identity_sources                  = []
    authorizer_result_ttl_in_seconds  = 0
    authorizer_payload_format_version = "2.0"
    authorizer_credentials_arn        = aws_iam_role.authorizer_lambda_trigger_role.arn
}

resource "aws_dynamodb_table" "authorized_users" {
  name           = "ninja-vpn-authorized_users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }

  tags = {
    Environment = "Dev"
  }
}