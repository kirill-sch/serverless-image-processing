data "archive_file" "image_upload_functions_lambda_zip" {
  source_dir  = "src/image/upload/python"
  output_path = "/tmp/image_upload_functions_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_dependencies]
}

resource "null_resource" "build_dependencies" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/upload/python/
    mkdir -p src/image/upload/python
    cp src/image/upload/lambda_function.py src/image/upload/requirements.txt src/image/upload/python
    python3 -m pip install -r src/image/upload/requirements.txt -t src/image/upload/python
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/upload/requirements.txt")
    source       = filemd5("src/image/upload/lambda_function.py")
  }
}

resource "aws_lambda_function" "image_upload_functions_lambda" {
  filename         = data.archive_file.image_upload_functions_lambda_zip.output_path
  function_name    = "${var.project_name}_image_upload_functions_lambda"
  description      = "Handler for image upload related operations."
  role             = aws_iam_role.image_upload_functions_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_upload_functions_lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  tracing_config {
    mode = var.lambda_tracing_config
  }

  environment {
    variables = {
      IMAGES_TABLE = aws_dynamodb_table.image_metadata_table.id
      BUCKET_NAME  = aws_s3_bucket.image_bucket.bucket
    }
  }
}

output "image_upload_functions_lambda" {
  value = aws_lambda_function.image_upload_functions_lambda.function_name
}
