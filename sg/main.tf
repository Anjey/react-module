terraform {
  required_version = ">= 1.0.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56.0"
    }
  }
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-"
  description = "SG for ${var.name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port       = element(split("-", ingress.value.port), 0)
      to_port         = element(split("-", ingress.value.port), 1) # Returns ingress.value.port[0] value if ingress.value.port[1] element does not exist
      protocol        = "tcp"
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", [])
      security_groups = lookup(ingress.value, "security_groups", [])
      description     = lookup(ingress.value, "description", "")
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = var.name }, var.tags)

  lifecycle { create_before_destroy = true }
}
