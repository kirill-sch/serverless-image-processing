resource "aws_iam_role" "sfn_role" {
  name        = "${var.project_name}_sfn_role"
  description = "SFN IAM role."
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "sfn_role_policy" {
  name = "${var.project_name}_sfn_role_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [
          aws_lambda_function.image_validate_functions_lambda.arn,
          aws_lambda_function.image_virus_scan_lambda.arn,
          aws_lambda_function.image_resize_lambda.arn
        ]
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

resource "aws_iam_policy_attachment" "sfn_attach" {
  name       = "${var.project_name}_sfn_attachment"
  roles      = [aws_iam_role.sfn_role.name]
  policy_arn = aws_iam_policy.sfn_role_policy.arn
}