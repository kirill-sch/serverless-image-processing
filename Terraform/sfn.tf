resource "aws_sfn_state_machine" "image_upload_workflow" {
  name = "${var.project_name}_image_upload_workflow"
  role_arn = aws_iam_role.sfn_role.arn
  definition = <<EOF
    {
    "StartAt": "image_validate",
    "States": {
        "image_validate": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.image_validate_functions_lambda.arn}",
            "ResultPath": "$.validation_result",
            "Next": "virus_scan",
            "TimeoutSeconds": 120,
            "Catch": [
                {
                    "ErrorEquals": [
                        "States.ALL"
                    ],
                    "ResultPath": "$.error",
                    "Next": "exception"
                }
            ]
        },
        "virus_scan": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.}",
            "ResultPath": "$.virus_scan_result",
            "Next": "check_scan_result",
            "TimeoutSeconds": 120,
            "Catch": [
                {
                    "ErrorEquals": [
                        "States.ALL"
                    ],
                    "ResultPath": "$.error",
                    "Next": "exception"
                }
            ]
        },
        "check_scan_result": {
            "Type": "Choice",
            "Choices": [
                {
                    "Variable": "$.scan_status",
                    "StringEquals": "clean",
                    "Next": "resize"
                },
                {
                    "Variable": "$.scan_status",
                    "StringEquals": "infected",
                    "Next": "exception"
                }
            ],
            "Default": "exception"
        },
        "resize": {
            "Type": "Task",
            "Resource": "${aws_lambda_function.}",
            "Next": "succeeded",
            "TimeoutSeconds": 120,
            "Catch": [
                {
                    "ErrorEquals": [
                        "States.ALL"
                    ],
                    "ResultPath": "$.error",
                    "Next": "exception"
                }
            ]
        },
        "exception": {
            "Type": "Task",
            "Resource": "",
            "ResultPath": "$.error.exception_handled",
            "Next": "failed"
        },
        "succeeded": {
            "End": true,
            "Type": "Pass"
        },
        "failed": {
            "Type": "Fail"
        }
    }
}
  EOF
}