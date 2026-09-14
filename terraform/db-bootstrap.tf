# One-shot Fargate task used to initialise the PostgreSQL databases.
# The task connects to the RDS "pcparts" database and creates the
# per-service databases if they do not already exist.

resource "aws_ecs_task_definition" "db_bootstrap" {
  family                   = "${local.resource_prefix}-db-bootstrap"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "db-bootstrap"
      image     = "postgres:17"
      essential = true

      environment = [
        {
          name  = "PGHOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "PGPORT"
          value = "5432"
        },
        {
          name  = "PGDATABASE"
          value = "pcparts"
        },
        {
          name  = "PGUSER"
          value = "postgres"
        },
        {
          name  = "PGSSLMODE"
          value = "require"
        }
      ]

      secrets = [
        {
          name      = "PGPASSWORD"
          valueFrom = "${aws_secretsmanager_secret.rds_master.arn}:password::"
        }
      ]

      command = [
        "bash",
        "-c",
        <<-EOT
          set -e

          echo "Waiting for PostgreSQL to become available..."

          until pg_isready; do
            sleep 5
          done

          echo "PostgreSQL is available."
          echo "Creating service databases..."

          psql -v ON_ERROR_STOP=1 <<'SQL'
          SELECT 'CREATE DATABASE customerdb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'customerdb'
          ) \gexec

          SELECT 'CREATE DATABASE productdb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'productdb'
          ) \gexec

          SELECT 'CREATE DATABASE orderdb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'orderdb'
          ) \gexec

          SELECT 'CREATE DATABASE inventorydb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'inventorydb'
          ) \gexec

          SELECT 'CREATE DATABASE paymentdb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'paymentdb'
          ) \gexec

          SELECT 'CREATE DATABASE shippingdb'
          WHERE NOT EXISTS (
            SELECT FROM pg_database WHERE datname = 'shippingdb'
          ) \gexec
          SQL

          echo "Database bootstrap completed successfully."
        EOT
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "db-bootstrap"
        }
      }
    }
  ])

  tags = {
    Name = "${local.resource_prefix}-db-bootstrap"
  }

  depends_on = [
    aws_db_instance.postgres
  ]
}