resource "aws_dynamodb_table" "state_locker" {
  name           = "ninja-vpn-tfstate-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Environment = "Dev"
  }
}