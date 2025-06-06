resource "aws_dynamodb_table" "image_metadata_table" {
  name         = "${var.project_name}_Image_Metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }
}

output "ImageMetadata" {
  value = aws_dynamodb_table.image_metadata_table.id
}