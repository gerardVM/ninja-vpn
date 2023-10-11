resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "daily_lambda_trigger"
  schedule_expression = "cron(0 */12 * * ? *)"  # Triggers every 12 hours

  # Targets the Lambda function
  event_pattern = jsonencode({
    source      = ["aws.lambda"]
    detail_type = ["Scheduled Event"]
    resources   = [aws_lambda_function.header_rotation.arn]
  })
}

resource "aws_lambda_permission" "cloudwatch_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.header_rotation.function_name

  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}