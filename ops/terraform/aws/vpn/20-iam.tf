resource "aws_iam_role" "role" {
  name = "ninja-vpn-${replace(split("@", local.config.email)[0], ".", "-")}-${local.config.region}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}

EOF
}

resource "aws_iam_role_policy_attachment" "s3_role_policy_policy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ses_role_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
  depends_on = [aws_iam_role_policy_attachment.s3_role_policy_policy]
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
  depends_on = [aws_iam_role_policy_attachment.ses_role_policy_attachment]
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  depends_on = [aws_iam_role_policy_attachment.lambda_role_policy_attachment]
}

resource "aws_iam_instance_profile" "profile" {
  name = "ninja-vpn-${replace(split("@", local.config.email)[0], ".", "-")}-${local.config.region}"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "fleet_role" {
  name = "ninja-fleet-${replace(split("@", local.config.email)[0], ".", "-")}-${local.config.region}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}

EOF
}

resource "aws_iam_role_policy_attachment" "fleet_role_policy_attachment" {
  role       = aws_iam_role.fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}