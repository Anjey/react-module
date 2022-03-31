variable "domain_name_www" {
  default = "www.react-project.romexsoft.net"
}

variable "buckets1" {
  default = {
    "acceleration_status"         = ""
    "acl"                         = "public-read"
    "arn"                         = "arn:aws:s3:::www.react-project.romexsoft.net"
    "bucket"                      = "www.react-project.romexsoft.net"
    "bucket_domain_name"          = "www.react-project.romexsoft.net.s3.amazonaws.com"
    "bucket_regional_domain_name" = "www.react-project.romexsoft.net.s3.us-east-2.amazonaws.com"
    "force_destroy"               = false
    "hosted_zone_id"              = "Z2O1EMRO9K5GLX"
    "id"                          = "www.react-project.romexsoft.net"
    "region"                      = "us-east-2"
    "request_payer"               = "BucketOwner"
    "website_domain"              = "s3-website.us-east-2.amazonaws.com"
    "website_endpoint"            = "www.react-project.romexsoft.net.s3-website.us-east-2.amazonaws.com"
  }
}

variable "buckets2" {
  default = {
    "acceleration_status"         = ""
    "acl"                         = "public-read"
    "arn"                         = "arn:aws:s3:::www.react-project.romexsoft.net"
    "bucket"                      = "www.react-project.romexsoft.net"
    "bucket_domain_name"          = "www.react-project.romexsoft.net.s3.amazonaws.com"
    "bucket_regional_domain_name" = "react-project.romexsoft.net.s3.us-east-2.amazonaws.com"
    "force_destroy"               = false
    "hosted_zone_id"              = "Z2O1EMRO9K5GLX"
    "id"                          = "react-project.romexsoft.net"
    "region"                      = "us-east-2"
    "request_payer"               = "BucketOwner"
    "website_domain"              = "s3-website.us-east-2.amazonaws.com"
    "website_endpoint"            = "www.react-project.romexsoft.net.s3-website.us-east-2.amazonaws.com"
  }
}