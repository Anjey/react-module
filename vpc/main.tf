# terraform {
#   required_version = ">= 1.0.4"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 3.56.0"
#     }
#   }
# }

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags       = merge({ Name = var.vpc_name }, var.tags)
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = element(var.private_subnets_cidrs, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = merge(
    { Name = join("_", ["private_subnet", var.vpc_name, data.aws_availability_zones.available.names[count.index]]) },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets_cidrs, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = "true"
  tags = merge(
    { Name = join("_", ["public_subnet", var.vpc_name, data.aws_availability_zones.available.names[count.index]]) },
    var.tags
  )
}


resource "aws_route_table" "private" {
  count = length(var.private_subnets_cidrs)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge({ Name = join("_", ["private_subnet_route", var.vpc_name]) }, var.tags)
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private[*].id)

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge({ Name = join("_", ["public_subnet_route", var.vpc_name]) }, var.tags)
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public[*].id)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge({ Name = join("_", ["IGW_", var.vpc_name]) }, var.tags)
}

resource "aws_eip" "nat" {
  count = length(var.private_subnets_cidrs)

  tags = merge({ Name = join("_", ["EIP_NAT", var.vpc_name]) }, var.tags)
}

resource "aws_nat_gateway" "this" {
  count = length(var.private_subnets_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public[*].id, count.index)
  tags          = merge({ Name = join("_", ["NAT_GW", var.vpc_name]) }, var.tags)

  depends_on = [aws_internet_gateway.this]
}


resource "aws_ssm_parameter" "eip" {
  name        = var.ssm_nat_eip
  description = "Static IP for accessing  via ssh"
  type        = "String"
  value       = jsonencode(aws_eip.nat[*].public_ip)
  overwrite   = true

  tags = merge({ Name = join("_", ["EIP_NAT", var.vpc_name]) }, var.tags)
}
