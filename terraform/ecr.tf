locals {
  ecr_repositories = {
    gateway        = "pc-parts-store-api-gateway"
    customer       = "pc-parts-store-customer-service"
    order          = "pc-parts-store-order-service"
    product        = "pc-parts-store-product-service"
    inventory      = "pc-parts-store-inventory-service"
    authentication = "pc-parts-store-authentication-service"
    payment        = "pc-parts-store-payment-service"
    shipping       = "pc-parts-store-shipping-service"
  }
}

resource "aws_ecr_repository" "service" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.value
  }
}