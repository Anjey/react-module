output "domain_names" {
  value = [
    for record in aws_route53_record.cloudfront :
    record.name
  ]
}

output "instance_ip" {
  value = module.ec2_instance.instances_eips
}
