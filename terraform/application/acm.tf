resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name       = "pcparts.craigfox.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.resource_prefix}-cloudfront-certificate"
  }
}

resource "aws_acm_certificate" "api" {
  domain_name       = "api.pcparts.craigfox.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.resource_prefix}-api-certificate"
  }
}