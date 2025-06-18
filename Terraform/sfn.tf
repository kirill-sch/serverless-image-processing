resource "aws_sfn_state_machine" "image_upload_workflow" {
  name     = "${var.project_name}_image_upload_workflow"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    StartAt = "validate"
    States = {
      validate = {
        Type           = "Task"
        Resource       = aws_lambda_function.image_validate_functions_lambda.arn
        ResultPath     = "$.validation_result"
        Next           = "virus_scan"
        TimeoutSeconds = 120
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "exception"
          }
        ]
      }
      virus_scan = {
        Type           = "Task"
        Resource       = aws_lambda_function.image_virus_scan_lambda.arn
        ResultPath     = "$.virus_scan_result"
        Next           = "check_scan_result"
        TimeoutSeconds = 120
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "exception"
          }
        ]
      }
      check_scan_result = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.virus_scan_result.scan_status"
            StringEquals = "clean"
            Next         = "resize"
          },
          {
            Variable     = "$.virus_scan_result.scan_status"
            StringEquals = "infected"
            Next         = "exception"
          }
        ]
        Default = "exception"
      }
      resize = {
        Type           = "Task"
        Resource       = aws_lambda_function.image_resize_lambda.arn
        ResultPath     = "$.resize_result"
        Next           = "submission"
        TimeoutSeconds = 120
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "exception"
          }
        ]
      }
      submission = {
        Type           = "Task"
        Resource       = aws_lambda_function.image_submission_functions_lambda.arn
        Next           = "succeeded"
        TimeoutSeconds = 120
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "exception"
          }
        ]
      }
      exception = {
        Type  = "Fail"
        Cause = "Image processing failed"
        Error = "ExceptionStateReached"
      }
      succeeded = {
        Type = "Pass"
        End  = true
      }
    }
  })
}