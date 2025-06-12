data "archive_file" "sfn_starter_lambda_zip" {
  source_dir = "src/image/sfn/python"
  output_path = "/tmp/sfn_starter_lambda_zip"
  type = "zip"
  depends_on = [ null_resource.dependency_builder_sfn_starter_lambda ]
}

resource "null_resource" "dependency_builder_sfn_starter_lambda" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/sfn/python/
    mkdir -p src/image/sfn/python
    cp src/image/sfn/lambda_function.py src/image/sfn/requirements.txt src/image/sfn/python
    python3 -m pip install -r src/image/sfn/requirements.txt -t src/image/sfn/python
    EOT
  }

  triggers = {
     dependencies = filemd5("src/image/sfn/requirements.txt")
    source       = filemd5("src/image/sfn/lambda_function.py")
  }
}

resource "aws_lambda_function" "sfn_starter" {
  filename = data.archive_file.sfn_starter_lambda_zip.output_path
  function_name = "${var.project_name}_sfn_starter_lambda"
  description = "This lambda will recieve the HTTP request and start the sfn."
  role = aws_iam_role.sfn_starter_lambda_role.arn
  handler = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.sfn_starter_lambda_zip.output_base64sha256
  runtime = var.lambda_runtime
  timeout = var.lambda_timeout

  tracing_config {
    mode = var.lambda_tracing_config
  }

  environment {
    variables = {
      SFN_ARN = aws_sfn_state_machine.image_upload_workflow.arn
    }
  }
}

output "sfn_starter_lambda" {
  value = aws_lambda_function.sfn_starter.function_name
}