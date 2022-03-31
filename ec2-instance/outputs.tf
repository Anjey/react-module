output "aws_instances_ids" {
  description = "List of instances ids"
  value       = aws_instance.this[*].id
}

output "instances_private_ips" {
  description = "List of private ips"
  value       = aws_instance.this[*].private_ip
}

output "instances_eips" {
  value = aws_eip.this[*].public_ip
}
