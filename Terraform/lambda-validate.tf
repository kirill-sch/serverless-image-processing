data "archive_file" "image_validate_functions_lambda_zip" {
  source_dir  = "src/image/validate/python"
  output_path = "/tmp/image_validate_functions_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_dependencies_for_image_validate]
}

resource "null_resource" "build_dependencies_for_image_validate" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/validate/python/
    mkdir -p src/image/validate/python
    cp src/image/validate/lambda_function.py src/image/validate/requirements.txt src/image/validate/python
    python3 -m pip install -r src/image/validate/requirements.txt -t src/image/validate/python
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/validate/requirements.txt")
    source       = filemd5("src/image/validate/lambda_function.py")
  }
}

resource "aws_lambda_function" "image_validate_functions_lambda" {
  filename         = data.archive_file.image_validate_functions_lambda_zip.output_path
  function_name    = "${var.project_name}_image_validate_functions_lambda"
  description      = "Handler for image validation related operations."
  role             = aws_iam_role.image_validate_functions_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_validate_functions_lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  tracing_config {
    mode = var.lambda_tracing_config
  }

  environment {
    variables = {
      IMAGES_TABLE = aws_dynamodb_table.image_metadata_table.id
    }
  }
}

output "image_validate_functions_lambda" {
  value = aws_lambda_function.image_validate_functions_lambda.function_name
}
