output "authorizer_uri" {
  value = "${aws_lambda_function.authorizer.invoke_arn}"
}
