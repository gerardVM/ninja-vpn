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

resource "aws_iam_policy" "vpn_controller_trigger" {
  name        = "vpn-controller-trigger"
  description = "Allows Lambda to depoy all necessary resources"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "InvokeLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.vpn_controller.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_role_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.vpn_controller_trigger.arn
}

resource "aws_sfn_state_machine" "lambda_trigger" {
  name     = "ninja-vpn-controller-trigger"
  role_arn = aws_iam_role.step_function_role.arn

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "LambdaInvokeDeploy",
  "States": {
    "LambdaInvokeDeploy": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload": {
          "ACTION": "deploy",
          "EMAIL.$": "$.EMAIL",
          "TIMEZONE.$": "$.TIMEZONE",
          "COUNTDOWN.$": "$.COUNTDOWN",
          "REGION.$": "$.REGION"
        },
        "FunctionName.$": "$.VPN_CONTROLLER_ARN"
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
      "Next": "Wait",
      "ResultPath": null
    },
    "Wait": {
      "Type": "Wait",
      "Seconds": 100,
      "Next": "LambdaInvokeDestroy",
      "InputPath": "$",
      "OutputPath": "$"
    },
    "LambdaInvokeDestroy": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload": {
          "ACTION": "destroy",
          "EMAIL.$": "$.EMAIL",
          "TIMEZONE.$": "$.TIMEZONE",
          "COUNTDOWN.$": "$.COUNTDOWN",
          "REGION.$": "$.REGION"
        },
        "FunctionName.$": "$.VPN_CONTROLLER_ARN"
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
      "End": true,
      "InputPath": "$"
    }
  }
}

EOF
}