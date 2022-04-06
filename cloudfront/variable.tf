variable "main_domain_name" {
  default     = ""
  type        = string
  description = "The main domain name in which will be redirecting"
}

variable "redirect_domain_name" {
  default     = ""
  type        = string
  description = "Domain name, website from which will be redirecting to main domain name. For example: domain.com -> www.domain.com"
}

variable "wait_for_validation" {
  default = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  type    = string
  default = ""
}

variable "cdn_enabled" {
  type    = bool
  default = true
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "allowed_methods" {
  type    = list(string)
  default = ["GET", "HEAD", "DELETE", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
  type    = list(string)
  default = ["GET", "HEAD"]
}

variable "viewer_protocol_policy" {
  type    = string
  default = "redirect-to-https"
}

variable "http_port" {
  type    = string
  default = "80"
}

variable "https_port" {
  description = ""
  type        = string
  default     = "443"
}

variable "origin_protocol_policy" {
  description = ""
  type        = string
  default     = "https-only"
}

variable "origin_ssl_protocols" {
  description = ""
  type        = list(string)
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "minimum_protocol_version" {
  type    = string
  default = "TLSv1.2_2021"
}

variable "ssl_support_method" {
  type    = string
  default = "sni-only"
}

variable "ssm_nat_eip" {
  description = "SSM path to store  nat EIPs"
  type        = string
  default     = "/adudych"
}

variable "ssh_whitelist" {
  description = "ssh whitelist to access EC2 instances"
  type        = map(any)
  default     = {}
}

variable "lb_deletion_protection" {
  description = "Enable Load Balancer deletion protection"
  type        = bool
  default     = true
}

variable "dns_name" {
  description = "Domain name without domain zone"
  type        = string
}

variable "min_ttl" {
  default = "0"
}

variable "default_ttl" {
  default = "300"
}

variable "max_ttl" {
  default = "1200"
}

variable "domain_redirect_enabled" {
  description = "Enable redirect domain to subdomain. For example: domain.com -> www.domain.com"
  type        = bool
  default     = false
}

variable "cdn_path_pattern" {
  description = "Path to allow entering backend"
  type        = list(string)
  default     = []
}

variable "admin_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "instance_root_volume_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}
