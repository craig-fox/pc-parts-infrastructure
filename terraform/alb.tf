resource "aws_security_group" "alb" {
  name        = "${local.resource_prefix}-alb-sg"
  description = "Security group for the application load balancer."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.resource_prefix}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

resource "aws_lb_target_group" "product" {
  name        = "${var.project_name}-${var.environment}-product"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "${local.resource_prefix}-product-targets"
  }
}


resource "aws_lb" "main" {
  name               = "${local.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = aws_subnet.public[*].id

  tags = {
    Name = "${local.resource_prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Product service ALB"
      status_code  = "200"
    }
  }

  tags = {
    Name = "${local.resource_prefix}-http-listener"
  }
}


resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.product.arn
      }
    }
  }

  condition {
    path_pattern {
      values = ["/api/products*"]
    }
  }
}

