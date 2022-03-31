output "bucket" {
  value = aws_s3_bucket.deploy_bucket
}

output "buckets" {
  value = local.buckets
}
