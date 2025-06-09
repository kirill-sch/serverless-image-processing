data "archive_file" "image_download_functions_lambda_zip" {
  source_dir  = "src/image/download/python"
  output_path = "/tmp/image_download_functions_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_dependencies_for_image_download]
}

resource "null_resource" "build_dependencies_for_image_download" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/download/python/
    mkdir -p src/image/download/python
    cp src/image/download/lambda_function.py src/image/download/requirements.txt src/image/download/python
    python3 -m pip install -r src/image/download/requirements.txt -t src/image/download/python
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/download/requirements.txt")
    source       = filemd5("src/image/download/lambda_function.py")
  }
}

resource "aws_lambda_function" "image_download_functions_lambda" {
  filename = data.archive_file.image_download_functions_lambda_zip.output_path
  function_name = "${var.project_name}"
  description = "Handler for image download related operations."
  role = aws_iam_role.image_download_functions_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_download_functions_lambda_zip.output_base64sha256
  runtime = var.lambda_runtime
  timeout = var.lambda_timeout

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

output "image_download_functions_lambda" {
  value = aws_lambda_function.image_download_functions_lambda.function_name
}