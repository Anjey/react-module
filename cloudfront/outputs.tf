output "domain_names" {
  value = [
    for record in aws_route53_record.cloudfront :
    record.name
  ]
}

output "instance_ip" {
  value = module.ec2_instance.instances_eips
}


# output "bucket_obj" {
#   value = [for k in aws_s3_bucket_object.website : k.etag]
# }
