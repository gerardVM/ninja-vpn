resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

}

resource "aws_iam_role_policy_attachment" "step_function_role_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sfn_state_machine" "lambda_trigger" {
  name     = "ninja-vpn-controller-trigger"
  role_arn = aws_iam_role.step_function_role.arn

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "AddVariable",
  "States": {
    "AddVariable": {
      "Type": "Pass",
      "Result": {
        "ACTION": "deploy",
        "EMAIL": "$.EMAIL",
        "TIMEZONE": "$.TIMEZONE",
        "COUNTDOWN": "$.COUNTDOWN",
        "REGION": "$.REGION"
      },
      "ResultPath": "$.updatedPayload",
      "Next": "LambdaInvokeDeploy"
    },
    "LambdaInvokeDeploy": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$.updatedPayload",
        "FunctionName": "arn:aws:lambda:eu-west-3:877759700856:function:ninja-vpn-controller:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "Next": "EditVariable"
    },
    "EditVariable": {
      "Type": "Pass",
      "Result": {
        "ACTION": "destroy",
        "EMAIL": "$.EMAIL",
        "TIMEZONE": "$.TIMEZONE",
        "COUNTDOWN": "$.COUNTDOWN",
        "REGION": "$.REGION"
      },
      "ResultPath": "$.updatedPayload",
      "Next": "Wait"
    },
    "Wait": {
      "Type": "Wait",
      "Seconds": 300,
      "Next": "LambdaInvokeDestroy"
    },
    "LambdaInvokeDestroy": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$.updatedPayload",
        "FunctionName": "arn:aws:lambda:eu-west-3:877759700856:function:ninja-vpn-controller:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}

EOF
}