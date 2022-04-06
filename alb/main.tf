terraform {
  required_version = ">= 1.0.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56.0"
    }
  }
}

resource "aws_lb" "this" {
  name                       = "${var.name}-lb"
  internal                   = false
  load_balancer_type         = "application"
  idle_timeout               = var.lb_idle_timeout
  security_groups            = var.security_groups
  subnets                    = var.subnets
  enable_deletion_protection = var.deletion_protection
  tags                       = var.tags
}


resource "aws_lb_target_group" "this" {
  name     = "${var.name}-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check_path
    interval            = var.health_check_interval
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
  }
  tags = var.tags

  lifecycle { create_before_destroy = true }
}


resource "aws_lb_listener" "listener80" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "listener443" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  lifecycle { create_before_destroy = true }
}

# resource "aws_lb_listener_rule" "reditect_apex" {
#   count = var.root_domain != "" ? 1 : 0

#   listener_arn = aws_lb_listener.listener443.arn
#   priority     = 103

#   action {
#     type = "redirect"

#     redirect {
#       host        = var.front_domain
#       path        = "/#{path}"
#       query       = "#{query}"
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }

#   condition {
#     host_header {
#       values = [var.root_domain]
#     }
#   }
# }


# Target Groups Attachments

resource "aws_lb_target_group_attachment" "admin" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.ec2_admin_instance_id
  port             = 80
}
