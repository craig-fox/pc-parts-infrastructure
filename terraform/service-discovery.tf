resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.${var.environment}"
  description = "Private service discovery namespace for ${var.project_name} ${var.environment}."
  vpc         = aws_vpc.main.id

  tags = {
    Name = "${local.resource_prefix}-service-discovery"
  }
}


resource "aws_service_discovery_service" "product" {
  name = "product-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = {
    Name = "${local.resource_prefix}-product-service-discovery"
  }
}