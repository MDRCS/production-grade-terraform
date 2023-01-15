resource "aws_lb" "api" {
  name               = "${local.prefix}-main"
  load_balancer_type = "application"

  security_groups = [aws_security_group.lb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]


  tags = local.common_tags
}

resource "aws_lb_target_group" "api" {
  name        = "${local.prefix}-api"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  port        = 8000

  health_check { # it perform periodic check on our application to ensure running.
    path = "/admin/login/"
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  # Best Practices
  # This commented code was here before creating HTTPS Listener,
  # Now we will try to `redirect` request from http to https to always use https for security Purposes
  # default_action {
  #   type             = "forward" # action is to forward requests to our application
  #   target_group_arn = aws_lb_target_group.api.arn
  # }

  default_action {
    type = "redirect" # redirect requests from http to https

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "api_https" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_security_group" "lb" {
  description = "Allow Access to application load balancer."
  name        = "${local.prefix}-lb"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = "443"
    to_port     = "443"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 8000
    to_port     = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}