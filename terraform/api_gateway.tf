resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = [
      "*",
      "http://s3-file-processor-output-it7iud.s3-website-us-east-1.amazonaws.com",
      "https://lambda.abilashnimmala.in"
    ]
    allow_methods = ["GET", "POST", "PUT", "OPTIONS"]
    allow_headers = ["*"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# Upload Integration
resource "aws_apigatewayv2_integration" "upload" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api_upload.invoke_arn
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /upload" # We use GET to get the presigned URL
  target    = "integrations/${aws_apigatewayv2_integration.upload.id}"
}

# Download Integration
resource "aws_apigatewayv2_integration" "download" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api_download.invoke_arn
}

resource "aws_apigatewayv2_route" "download" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /download"
  target    = "integrations/${aws_apigatewayv2_integration.download.id}"
}

# Permissions for API Gateway to invoke Lambdas
resource "aws_lambda_permission" "api_upload" {
  statement_id  = "AllowAPIGatewayInvokeUpload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_download" {
  statement_id  = "AllowAPIGatewayInvokeDownload"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_download.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
