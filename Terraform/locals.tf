locals {
  dynamodb_table_arn = "arn:*:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${aws_dynamodb_table.image_metadata_table.name}"
  s3_uploads_arn     = "arn:*:s3:::${aws_s3_bucket.image_bucket.bucket}/uploads/*"
}