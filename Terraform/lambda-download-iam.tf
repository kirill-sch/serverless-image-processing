resource "aws_iam_role" "image_download_functions_lambda_role" {
  name = "${var.project_name}_image_download_functions_lambda_role"
  description = "Download image lambda function IAM role"
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

resource "aws_iam_policy" "image_download_functions_lambda_role_policy" {
  name = "${var.project_name}_image_download_functions_lambda_role_policy"
  description = "Lambda function policy for image upload"

  policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.image_bucket.bucket}/uploads/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem"
      ],
      "Resource": "arn:*:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.image_metadata_table.name}"
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
EOF
}

resource "aws_iam_policy_attachment" "image_download_functions_lambda_attach" {
  name = "${var.project_name}_image_download_functions_lambda_attachment"
  roles = [ aws_iam_role.image_download_functions_lambda_role.name ]
  policy_arn = aws_iam_policy.image_download_functions_lambda_role_policy.arn
}