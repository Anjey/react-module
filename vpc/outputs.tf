output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "nat_eip" {
  value     = aws_ssm_parameter.eip.value
  sensitive = false
}
