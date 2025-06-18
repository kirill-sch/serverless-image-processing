data "archive_file" "image_submission_functions_lambda_zip" {
  source_dir  = "src/image/submission/python"
  output_path = "/tmp/image_submission_functions_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_dependencies_for_image_submission]
}

resource "null_resource" "build_dependencies_for_image_submission" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/submission/python/
    mkdir -p src/image/submission/python
    cp src/image/submission/lambda_function.py src/image/submission/requirements.txt src/image/submission/python
    python3 -m pip install -r src/image/submission/requirements.txt -t src/image/submission/python
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/submission/requirements.txt")
    source       = filemd5("src/image/submission/lambda_function.py")
  }
}

resource "aws_lambda_function" "image_submission_functions_lambda" {
  filename         = data.archive_file.image_submission_functions_lambda_zip.output_path
  function_name    = "${var.project_name}_image_submission_functions_lambda"
  description      = "Handler for image validation related operations."
  role             = aws_iam_role.image_submission_functions_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_submission_functions_lambda_zip.output_base64sha256
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

output "image_submission_functions_lambda" {
  value = aws_lambda_function.image_submission_functions_lambda.function_name
}
