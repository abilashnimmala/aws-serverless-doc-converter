resource "aws_s3_bucket" "input_bucket" {
  bucket = "${var.project_name}-input-${random_string.suffix.result}"
}

resource "aws_s3_bucket_cors_configuration" "input_cors" {
  bucket = aws_s3_bucket.input_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = ["*"] # For testing, can be restricted later
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "${var.project_name}-output-${random_string.suffix.result}"
}

resource "aws_s3_bucket_website_configuration" "hosting" {
  bucket = aws_s3_bucket.output_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.output_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.output_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.output_bucket.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.hosting.website_endpoint}"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

output "input_bucket_name" {
  value = aws_s3_bucket.input_bucket.id
}

output "output_bucket_name" {
  value = aws_s3_bucket.output_bucket.id
}
