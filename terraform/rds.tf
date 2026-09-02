# RDS subnet group
resource "aws_db_subnet_group" "main" {
  name = "${local.resource_prefix}-rds"

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.resource_prefix}-rds-subnet-group"
  }
}

# Security group for RDS PostgreSQL
resource "aws_security_group" "rds" {
  name        = "${local.resource_prefix}-rds-sg"
  description = "Security group for PostgreSQL RDS."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.resource_prefix}-rds-sg"
  }
}

# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier = "${local.resource_prefix}-postgres"

  engine         = "postgres"
  engine_version = "17"

  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "pcparts"
  username = "postgres"
  password = random_password.rds_master.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window           = "18:00-19:00"

  maintenance_window = "sun:19:00-sun:20:00"

  auto_minor_version_upgrade = true
  apply_immediately          = true

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${local.resource_prefix}-postgres"
  }

  depends_on = [
    aws_secretsmanager_secret_version.rds_master
  ]
}