resource "aws_ecs_cluster" "main" {
  name = "${local.resource_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.resource_prefix}-cluster"
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_execution" {
  name = "${local.resource_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.resource_prefix}-ecs-execution-role"
  }
}

# ECS task role
resource "aws_iam_role" "ecs_task" {
  name = "${local.resource_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.resource_prefix}-ecs-task-role"
  }
}

# Execution-role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.resource_prefix}"
  retention_in_days = 14

  tags = {
    Name = "${local.resource_prefix}-ecs-logs"
  }
}

# ECS security group
resource "aws_security_group" "ecs" {
  name        = "${local.resource_prefix}-ecs-sg"
  description = "Security group for ECS tasks."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.resource_prefix}-ecs-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"
}

