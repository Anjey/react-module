terraform {
  required_version = ">= 1.0.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.56.0"
    }
  }
}

locals {

}

resource "aws_instance" "this" {
  count = var.instance_count

  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  associate_public_ip_address = var.associate_public_ip_address
  #   iam_instance_profile        = var.iam_instance_profile
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = element(var.subnets_ids, count.index)
  tags                   = var.tags

  root_block_device {
    volume_size = var.root_volume_size
  }

  lifecycle {
    ignore_changes        = [associate_public_ip_address]
    create_before_destroy = true
  }
}

resource "aws_eip" "this" {
  count    = var.associate_elastic_ip_address ? var.instance_count : 0
  vpc      = true
  instance = aws_instance.this[count.index].id
  tags     = var.tags
}
