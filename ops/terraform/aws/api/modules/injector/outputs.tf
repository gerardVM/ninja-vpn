output "qualified_arn" {
  value = "${aws_lambda_function.injector.qualified_arn}"
}

output "function_name" {
  value = "${aws_lambda_function.injector.function_name}"
}
