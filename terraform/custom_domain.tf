# Add this to a new file: terraform/custom_domain.tf

variable "custom_domain_name" {
  default = "lambda.abilashnimmala.in"
}

# 1. Request an SSL Certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = var.custom_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 2. Create the Custom Domain Name in API Gateway
resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = var.custom_domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# 3. Map the Domain to our API
resource "aws_apigatewayv2_api_mapping" "mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.default.id
}

# Outputs for GoDaddy setup
output "acm_dns_validation_record" {
  description = "Add this CNAME record to GoDaddy to verify domain ownership"
  value       = aws_acm_certificate.cert.domain_validation_options
}

output "api_gateway_target_domain" {
  description = "Point your lambda.abilashnimmala.in CNAME to this value in GoDaddy"
  value       = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
}
