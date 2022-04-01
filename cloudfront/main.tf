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
  react_dir            = "${path.module}/../../../../../../../../../react-code"
  react_build_dir      = "${local.react_dir}/build/"
  react_package        = "package.json"
  react_app            = "App.js"
  aws_ami_backend_name = "ami-0cf6039178fba16d7"
  public_key           = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcw/EMwquklJpalpwUXFDMqQPBNQEP7MotLB+TijctjsGtuN3BlI5r04w+2oI02y5ksSJyi6k2TsW/vmZA23KkJ1pbLcUv4C3C48pmGhaAoC9fBSxJwB05ofR13CGYyfgJsAqAyM8jlE2Tf5y0oVGb7jA7ln8+chcVQGv0u7UlKU4NWaF4tvmcGlVr2nqIr1lSRW+EYAEpd9Sww3HLGn3a5t0JH98o5+yPwm/+ow9GDVfja2lTFMNl3WDlvY3oDU02I7TAXqLZCGXSGZuZSjWXvD+kYwPFbPC8OlMC0YO4Xn0q9nB+xiqJ1GtXO5asy/kO/kygFxH9ntVisYZ4zPMh test-adudych"

  cdns = var.domain_redirect_enabled ? {
    cdn1 = aws_cloudfront_distribution.website_cdn
    cdn2 = aws_cloudfront_distribution.website_cdn_redirect[0]
    } : {
    cdn1 = aws_cloudfront_distribution.website_cdn
  }

  cdn_data = { for k, v in local.cdns : k =>
    {
      cdn_name    = v.domain_name
      cdn_zone_id = v.hosted_zone_id
      cdn_alias   = join("", v.aliases)
  } }

  ingress_rules = [
    { port = "80", cidr_blocks = ["0.0.0.0/0"], description = "HTTP from anywhere" },
    { port = "443", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS from anywhere" },
    { port = "0", protocol = "-1", cidr_blocks = formatlist("%s/32", jsondecode(module.vpc.nat_eip)), description = "Full access for NAT IP" }
  ]

  ingress_rules_full = {
    alb = concat(
      local.ingress_rules,
      [for ip, description in var.ssh_whitelist : { port = "0", protocol = "-1", cidr_blocks = ["${ip}/32"], description = description }]
    )
  }

  tags = merge({ environment = var.environment }, var.tags)
}



data "aws_route53_zone" "selected" {
  name         = "romexsoft.net"
  private_zone = false
}

# data "aws_ssm_parameter" "nat_eip" {
#   name = var.ssm_nat_eip
# }

# data "aws_ami" "ubuntu_backend" {
#   # most_recent = true
#   filter {
#     name   = "image-id"
#     values = [local.aws_ami_backend_name]
#   }
#   owners = ["319448237430"]
# }

resource "aws_key_pair" "this" {
  key_name_prefix = var.dns_name
  public_key      = local.public_key
  tags            = local.tags
}

module "vpc" {
  source                = "../vpc"
  vpc_name              = "${var.dns_name}-vpc"
  vpc_cidr_block        = "10.0.0.0/16"
  private_subnets_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]
  public_subnets_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  ssm_nat_eip           = var.ssm_nat_eip
  tags                  = local.tags
}

module "sg" {
  for_each = local.ingress_rules_full

  source        = "../sg"
  vpc_id        = module.vpc.vpc_id
  name          = "${var.dns_name}-alb"
  ingress_rules = each.value
  tags          = local.tags
}

module "alb" {
  source                = "../alb"
  name                  = "${var.dns_name}-alb"
  vpc_id                = module.vpc.vpc_id
  security_groups       = [module.sg["alb"].id]
  subnets               = module.vpc.public_subnets[*]
  ssl_certificate_arn   = aws_acm_certificate.second.arn
  ec2_admin_instance_id = module.ec2_instance.aws_instances_ids[0]
  deletion_protection   = var.lb_deletion_protection
  tags                  = local.tags

  # depends_on = [
  #   module.vpc
  # ]
}

module "ec2_instance" {
  source                       = "../ec2-instance"
  instance_name                = "${var.dns_name}-backend"
  instance_count               = 1
  ami                          = local.aws_ami_backend_name
  instance_type                = var.admin_instance_type
  ssh_key_name                 = aws_key_pair.this.id
  associate_elastic_ip_address = true
  subnets_ids                  = module.vpc.public_subnets
  root_volume_size             = var.instance_root_volume_size
  tags                         = local.tags
  vpc_security_group_ids       = [module.sg["alb"].id]
  # iam_instance_profile         = aws_iam_instance_profile.instance["admin"].name
  # sns_topic_arn                = module.sns_alerts.sns_topic_arn
}

resource "aws_s3_bucket" "website" {
  bucket = var.domain_name
  acl    = "private"
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket" "website_redirect" {
  count = var.domain_redirect_enabled ? 1 : 0

  bucket = var.sub_domain_name
  acl    = "private"
  website {
    redirect_all_requests_to = aws_s3_bucket.website.id
  }
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn,
      ]
    }
  }
}

resource "aws_acm_certificate" "this" {
  provider                  = aws.virginia
  domain_name               = var.domain_name
  subject_alternative_names = var.domain_redirect_enabled ? [var.sub_domain_name] : []
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "second" {
  domain_name               = var.domain_name
  subject_alternative_names = var.domain_redirect_enabled ? [var.sub_domain_name] : []
  validation_method         = "DNS"
  tags                      = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for certificate in aws_acm_certificate.this.domain_validation_options : certificate.domain_name => {
      name   = certificate.resource_record_name
      record = certificate.resource_record_value
      type   = certificate.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${aws_s3_bucket.website.id}"
}

resource "aws_cloudfront_distribution" "website_cdn" {
  enabled             = var.cdn_enabled
  price_class         = var.price_class
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  origin {
    origin_id   = "origin-bucket-${var.domain_name}"
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  origin {
    origin_id           = "origin-alb-${var.domain_name}"
    domain_name         = module.alb.alb_domain_name
    connection_attempts = 3
    connection_timeout  = 10
    custom_origin_config {
      http_port              = var.http_port
      https_port             = var.https_port
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = var.origin_ssl_protocols
    }

  }
  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    min_ttl                = var.min_ttl
    default_ttl            = var.default_ttl
    max_ttl                = var.max_ttl
    target_origin_id       = "origin-bucket-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  dynamic "ordered_cache_behavior" {
    for_each = var.cdn_path_pattern
    content {
      path_pattern     = ordered_cache_behavior.value
      allowed_methods  = var.allowed_methods
      cached_methods   = var.cached_methods
      target_origin_id = "origin-alb-${var.domain_name}"

      forwarded_values {
        query_string = false
        headers      = ["Host"]

        cookies {
          forward = "none"
        }
      }
      min_ttl                = var.min_ttl
      default_ttl            = var.default_ttl
      max_ttl                = var.max_ttl
      compress               = true
      viewer_protocol_policy = var.viewer_protocol_policy
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate.this.arn
    ssl_support_method             = var.ssl_support_method
    minimum_protocol_version       = var.minimum_protocol_version
  }
  tags = merge({ Name = var.domain_name }, local.tags)

  lifecycle {
    ignore_changes = [viewer_certificate]
    # prevent_destroy = true
  }
}

resource "aws_cloudfront_distribution" "website_cdn_redirect" {
  count = var.domain_redirect_enabled ? 1 : 0

  enabled             = var.cdn_enabled
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = [var.sub_domain_name]
  origin {
    origin_id           = "origin-bucket-${var.sub_domain_name}"
    domain_name         = aws_s3_bucket.website_redirect[0].website_endpoint
    connection_attempts = 3
    connection_timeout  = 10
    custom_origin_config {
      http_port              = var.http_port
      https_port             = var.https_port
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = var.origin_ssl_protocols
    }
  }
  default_cache_behavior {
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    min_ttl                = "0"
    default_ttl            = "300"
    max_ttl                = "1200"
    target_origin_id       = "origin-bucket-${var.sub_domain_name}"
    viewer_protocol_policy = var.viewer_protocol_policy
    compress               = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate.this.arn
    ssl_support_method             = var.ssl_support_method
    minimum_protocol_version       = var.minimum_protocol_version
  }
  tags = merge({ Name = var.sub_domain_name }, local.tags)

  lifecycle {
    ignore_changes = [origin, viewer_certificate]
    # prevent_destroy = true
  }
}


resource "aws_route53_record" "cloudfront" {
  for_each = local.cdn_data

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.cdn_alias
  type    = "A"
  alias {
    name                   = each.value.cdn_name
    zone_id                = each.value.cdn_zone_id
    evaluate_target_health = false
  }
}

resource "null_resource" "bucket_object" {
  provisioner "local-exec" {
    command = "aws s3 sync ${local.react_build_dir} s3://${aws_s3_bucket.website.id}"
  }
  triggers = {
    react_package_hash = filemd5("${local.react_dir}/${local.react_package}")
    react_app_hash     = filemd5("${local.react_dir}/src/${local.react_app}")
  }
  depends_on = [
    aws_s3_bucket.website
  ]
}

resource "null_resource" "cdn_invalidation" {
  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website_cdn.id} --paths '/*'"
  }
  triggers = {
    bucket_object_change = null_resource.bucket_object.id
  }
  depends_on = [
    aws_cloudfront_distribution.website_cdn,
    null_resource.bucket_object
  ]
}
