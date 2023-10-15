resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily_lambda_trigger"
  schedule_expression = "rate(12 hours)"  # Triggers every 12 hours
}

resource "aws_cloudwatch_event_target" "header_rotation" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "header_rotation"

  arn       = aws_lambda_function.header_rotation.arn
}

resource "aws_lambda_permission" "cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.header_rotation.function_name

  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}