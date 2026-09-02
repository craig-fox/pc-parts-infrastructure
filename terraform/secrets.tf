resource "aws_secretsmanager_secret" "rds_master" {
  name                    = "${local.resource_prefix}/rds/master"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.resource_prefix}-rds-master-secret"
  }
}

resource "random_password" "rds_master" {
  length           = 32
  special          = true
  override_special = "!#$%&*+-=?^_"
}

resource "aws_secretsmanager_secret_version" "rds_master" {
  secret_id = aws_secretsmanager_secret.rds_master.id

  secret_string = jsonencode({
    username = "postgres"
    password = random_password.rds_master.result
  })
}


resource "aws_secretsmanager_secret" "jwt" {
  name                    = "${local.resource_prefix}/jwt"
  recovery_window_in_days = 0

  tags = {
    Name = "${local.resource_prefix}-jwt-secret"
  }
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id     = aws_secretsmanager_secret.jwt.id
  secret_string = random_password.jwt.result
}