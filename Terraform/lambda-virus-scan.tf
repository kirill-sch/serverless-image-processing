data "archive_file" "image_virus_scan_lambda_zip" {
  source_dir  = "src/image/virus_scan/python"
  output_path = "/tmp/image_virus_scan_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_for_image_virus_scan]
}

resource "null_resource" "build_for_image_virus_scan" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/virus_scan/python/
    mkdir -p src/image/virus_scan/python
    cp src/image/virus_scan/lambda_function.py src/image/virus_scan/requirements.txt src/image/virus_scan/python
    python3 -m pip install -r src/image/virus_scan/requirements.txt -t src/image/virus_scan/python
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/virus_scan/requirements.txt")
    source       = filemd5("src/image/virus_scan/lambda_function.py")
  }
}

resource "aws_lambda_function" "image_virus_scan_lambda" {
  filename         = data.archive_file.image_virus_scan_lambda_zip.output_path
  function_name    = "${var.project_name}_image_virus_scan_lambda"
  description      = "Handler for image virus scanning related operations."
  role             = aws_iam_role.image_virus_scan_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_virus_scan_lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  tracing_config {
    mode = var.lambda_tracing_config
  }
}

output "image_virus_scan_lambda" {
  value = aws_lambda_function.image_virus_scan_lambda.function_name
}
