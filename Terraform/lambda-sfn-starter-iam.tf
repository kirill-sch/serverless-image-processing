resource "aws_iam_role" "sfn_starter_lambda_role" {
  name               = "${var.project_name}_sfn_starter_lambda_role"
  description        = "SFN starter lambda function IAM role."
  assume_role_policy = <<EOF
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
  EOF
}

resource "aws_iam_policy" "sfn_starter_lambda_role_policy" {
  name        = "${var.project_name}_sfn_starter_lambda_role_policy"
  description = "Lambda function policy for sfn starter."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "states:StartExecution"
        ],
        Resource = aws_sfn_state_machine.image_upload_workflow.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "sfn_starter_lambda_attach" {
  name       = "${var.project_name}_sfn_starter_lambda_attachment"
  roles      = [aws_iam_role.sfn_starter_lambda_role.name]
  policy_arn = aws_iam_policy.sfn_starter_lambda_role_policy.arn
}