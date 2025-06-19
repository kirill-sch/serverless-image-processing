data "archive_file" "image_resize_lambda_zip" {
  source_dir  = "src/image/resize/python"
  output_path = "/tmp/image_resize_lambda.zip"
  type        = "zip"
  depends_on  = [null_resource.build_for_image_resize]
}

resource "null_resource" "build_for_image_resize" {
  provisioner "local-exec" {
    command = <<EOT
    rm -rf src/image/resize/python/
    mkdir -p src/image/resize/python

    docker build -t lambda-builder -f src/image/resize/Dockerfile.lambda-builder src/image/resize
    docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/src/image/resize/python":/out lambda-builder     

    cp src/image/resize/lambda_function.py src/image/resize/python    
    EOT
  }

  triggers = {
    dependencies = filemd5("src/image/resize/requirements.txt")
    source       = filemd5("src/image/resize/lambda_function.py")
    dockerfile = filemd5("src/image/resize/Dockerfile.lambda-builder")
  }
}

# Why is there a change here? 
# - Pillow is a binary package, meaning it contains compiled code (e.g. C/C++),
# not just pure Python.
# Because AWS Lambda runs on Amazon Linux 2, such packages
# must be built in a compatible environment. We use Docker to simulate Lambda's
# environment and install the dependencies there to avoid runtime errors.
# What is a binary package?
# - A binary package is a Python package that includes compiled (machine-readable)
# code—not just plain Python .py files.

resource "aws_lambda_function" "image_resize_lambda" {
  filename         = data.archive_file.image_resize_lambda_zip.output_path
  function_name    = "${var.project_name}_image_resize_lambda"
  description      = "Handler for image virus scanning related operations."
  role             = aws_iam_role.image_resize_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.image_resize_lambda_zip.output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout

  tracing_config {
    mode = var.lambda_tracing_config
  }
}

output "image_resize_lambda" {
  value = aws_lambda_function.image_resize_lambda.function_name
}
