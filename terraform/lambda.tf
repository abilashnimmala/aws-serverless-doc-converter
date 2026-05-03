data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../build"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "s3_processor" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = 30 # Conversion might take longer
  memory_size      = 256 # More memory for PDF generation

  environment {
    variables = {
      OUTPUT_BUCKET_NAME = aws_s3_bucket.output_bucket.id
    }
  }
}

resource "aws_lambda_function" "api_upload" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-api-upload"
  role             = aws_iam_role.lambda_role.arn
  handler          = "api_upload.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      INPUT_BUCKET_NAME = aws_s3_bucket.input_bucket.id
    }
  }
}

resource "aws_lambda_function" "api_download" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-api-download"
  role             = aws_iam_role.lambda_role.arn
  handler          = "api_download.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      OUTPUT_BUCKET_NAME = aws_s3_bucket.output_bucket.id
    }
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_bucket.arn
}

# S3 Trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
