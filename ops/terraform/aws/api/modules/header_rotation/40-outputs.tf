output "parameter_arn" {
  value = aws_ssm_parameter.ninja-vpn-authorization-header-value.arn
}

output "header_value" {
  value = aws_ssm_parameter.ninja-vpn-authorization-header-value.value
}