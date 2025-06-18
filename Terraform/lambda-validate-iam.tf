resource "aws_iam_role" "image_validate_functions_lambda_role" {
  name               = "${var.project_name}_image_validate_functions_lambda_role"
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

resource "aws_iam_policy" "image_validate_functions_lambda_role_policy" {
  name        = "${var.project_name}_image_validate_functions_lamda_role_policy"
  description = "Lambda function policy for image validate"

  policy = <<EOT
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [        
        "dynamodb:PutItem"
      ],
      "Resource": "${local.dynamodb_table_arn}"
    },
    {
      "Effect": "Allow",
      "Action": "logs:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "xray:*",
      "Resource": "*"
    }
  ]
}
  EOT
}

resource "aws_iam_policy_attachment" "image_validate_functions_lambda_attach" {
  name       = "${var.project_name}_image_validate_functions_lambda_attachment"
  roles      = [aws_iam_role.image_validate_functions_lambda_role.name]
  policy_arn = aws_iam_policy.image_validate_functions_lambda_role_policy.arn
}
