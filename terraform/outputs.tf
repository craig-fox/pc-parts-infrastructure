output "bucket_name" {
  description = "Name of the S3 bucket hosting the frontend."
  value       = aws_s3_bucket.frontend.bucket
}

output "bucket_arn" {
  description = "ARN of the frontend S3 bucket."
  value       = aws_s3_bucket.frontend.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for the frontend."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_url" {
  description = "URL of the frontend application."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "vpc_id" {
  description = "ID of the application VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for application services."
  value = {
    for service, repository in aws_ecr_repository.service :
    service => repository.repository_url
  }
}

output "rds_subnet_group_name" {
  description = "Name of the RDS DB subnet group."
  value       = aws_db_subnet_group.main.name
}

output "rds_security_group_id" {
  description = "Security group ID for the RDS PostgreSQL instance."
  value       = aws_security_group.rds.id
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the PostgreSQL RDS instance."
  value       = aws_db_instance.postgres.port
}

output "rds_secret_arn" {
  description = "ARN of the RDS master credentials secret."
  value       = aws_secretsmanager_secret.rds_master.arn
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks."
  value       = aws_security_group.ecs.id
}