locals {
  resource_prefix = "${var.project_name}-${var.component}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Component   = var.component
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  frontend_bucket_name = var.bucket_name
}