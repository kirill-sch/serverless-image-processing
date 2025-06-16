resource "aws_iam_role" "image_resize_lambda_role" {
  name               = "${var.project_name}_image_resize_lambda_role"
  description        = "Virus scan image lambda function IAM role"
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

resource "aws_iam_policy" "image_resize_lambda_role_policy" {
  name        = "${var.project_name}_image_resize_lamda_role_policy"
  description = "Lambda function policy for image virus scanning"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
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

resource "aws_iam_policy_attachment" "image_resize_lambda_attach" {
  name       = "${var.project_name}_image_resize_lambda_attachment"
  roles      = [aws_iam_role.image_resize_lambda_role.name]
  policy_arn = aws_iam_policy.image_resize_lambda_role_policy.arn
}
