resource "random_password" "ssm_initial_value" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "aws_ssm_parameter" "ninja-vpn-authorization-header-value" {
  name      = "ninja-vpn-authorization-header"
  type      = "SecureString"
  value     = random_password.ssm_initial_value.result
  tier      = "Standard"
}