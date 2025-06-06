resource "aws_s3_bucket" "image_bucket" {
  bucket = "${var.project_name}-kirill-project" 
  force_destroy = true
}