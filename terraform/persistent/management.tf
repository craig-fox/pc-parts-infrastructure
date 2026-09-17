data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

resource "aws_security_group" "management" {
  name        = "${local.resource_prefix}-management-sg"
  description = "Security group for the dev management instance."
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.resource_prefix}-management-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres_from_management" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.management.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  description = "Allow management instance to access PostgreSQL."
}

resource "aws_iam_role" "management" {
  name = "${local.resource_prefix}-management-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "management_ssm" {
  role       = aws_iam_role.management.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "management" {
  name = "${local.resource_prefix}-management-profile"
  role = aws_iam_role.management.name
}

resource "aws_instance" "management" {
  count = var.environment == "dev" ? 1 : 0

  ami           = data.aws_ssm_parameter.al2023_arm64.value
  instance_type = "t4g.nano"

  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.management.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.management.name

  tags = {
    Name = "${local.resource_prefix}-management"
  }
}