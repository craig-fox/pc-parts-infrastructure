variable "aws_region" {
  description = "AWS region in which to create resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition = contains(["dev", "test", "prod"], var.environment)

    error_message = "Environment must be one of: dev, test or prod."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket used to host the frontend."
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "pc-parts-store"
}

variable "component" {
  description = "Application component being deployed."
  type        = string
  default     = "frontend"
}