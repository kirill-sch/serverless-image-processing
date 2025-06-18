resource "aws_iam_role" "image_submission_functions_lambda_role" {
  name               = "${var.project_name}_image_submission_lambda_role"
  description        = "Validate image lambda function IAM role"
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

resource "aws_iam_policy" "image_submission_functions_lambda_role_policy" {
  name        = "${var.project_name}_image_submission_lamda_role_policy"
  description = "Lambda function policy for image submission"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:UpdateItem"
        ],
        Resource = local.dynamodb_table_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = local.s3_uploads_arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      },
      {
        Action = [
          "xray:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "image_submission_functions_lambda_attach" {
  name       = "${var.project_name}_image_submission_lambda_attachment"
  roles      = [aws_iam_role.image_submission_functions_lambda_role.name]
  policy_arn = aws_iam_policy.image_submission_functions_lambda_role_policy.arn
}
