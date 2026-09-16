data "aws_route53_zone" "craigfox_dev" {
  name         = "craigfox.dev"
  private_zone = false
}

resource "aws_route53_record" "cloudfront_certificate_validation" {
  for_each = toset([
    "pcparts.craigfox.dev"
  ])

  zone_id = data.aws_route53_zone.craigfox_dev.zone_id

  name = one([
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
    dvo.resource_record_name
    if dvo.domain_name == each.key
  ])

  type = one([
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
    dvo.resource_record_type
    if dvo.domain_name == each.key
  ])

  ttl = 60

  records = [
    one([
      for dvo in aws_acm_certificate.cloudfront.domain_validation_options :
      dvo.resource_record_value
      if dvo.domain_name == each.key
    ])
  ]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.cloudfront.arn

  validation_record_fqdns = [
    for record in aws_route53_record.cloudfront_certificate_validation :
    record.fqdn
  ]
}

resource "aws_route53_record" "pcparts" {
  zone_id = data.aws_route53_zone.craigfox_dev.zone_id
  name    = "pcparts.craigfox.dev"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_pcparts" {
  zone_id = data.aws_route53_zone.craigfox_dev.zone_id
  name    = "api.pcparts.craigfox.dev"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api_certificate_validation" {
  for_each = toset([
    "api.pcparts.craigfox.dev"
  ])

  zone_id = data.aws_route53_zone.craigfox_dev.zone_id

  name = one([
    for dvo in aws_acm_certificate.api.domain_validation_options :
    dvo.resource_record_name
    if dvo.domain_name == each.key
  ])

  type = one([
    for dvo in aws_acm_certificate.api.domain_validation_options :
    dvo.resource_record_type
    if dvo.domain_name == each.key
  ])

  ttl = 60

  records = [
    one([
      for dvo in aws_acm_certificate.api.domain_validation_options :
      dvo.resource_record_value
      if dvo.domain_name == each.key
    ])
  ]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn = aws_acm_certificate.api.arn

  validation_record_fqdns = [
    for record in aws_route53_record.api_certificate_validation :
    record.fqdn
  ]
}