resource "aws_iam_role" "image_upload_functions_lambda_role" {
  name               = "${var.project_name}_imagefunctions_lambda_role"
  description        = "Lambda function IAM role"
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

resource "aws_iam_policy" "image_upload_functions_lambda_role_policy" {
  name        = "${var.project_name}_imagefunctions_lamda_role_policy"
  description = "Lambda function policy"

  policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {      
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": "arn:*:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.image_metadata_table.name}"
    },
    {      
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:*:s3:::${aws_s3_bucket.image_bucket.bucket}/uploads/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:*"
        ],
        "Resource": "*"
    },
    {
      "Action": [
        "xray:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "image_upload_functions_lambda_attach" {
  name       = "${var.project_name}_image_upload_functions_lambda_attachment"
  roles      = [aws_iam_role.image_upload_functions_lambda_role.name]
  policy_arn = aws_iam_policy.image_upload_functions_lambda_role_policy.arn
}