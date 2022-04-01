output "domain_name" {
  value = [
    for record in aws_route53_record.cloudfront :
    record.name
  ]
}

output "buckets_redirect" {
  value = aws_s3_bucket.website_redirect
}
