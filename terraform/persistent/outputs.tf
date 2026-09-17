output "vpc_id" {
  description = "ID of the persistent application VPC."
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

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the PostgreSQL RDS instance."
  value       = aws_db_instance.postgres.port
}

output "rds_security_group_id" {
  description = "Security group ID for the RDS PostgreSQL instance."
  value       = aws_security_group.rds.id
}

output "rds_secret_arn" {
  description = "ARN of the RDS master credentials secret."
  value       = aws_secretsmanager_secret.rds_master.arn
}

output "jwt_secret_arn" {
  description = "ARN of the persistent JWT signing secret."
  value       = aws_secretsmanager_secret.jwt.arn
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway used by private subnets."
  value       = aws_nat_gateway.main.id
}
