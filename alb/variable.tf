variable "name" {
  description = "Name or name prefix for resources"
  type        = string
}

variable "lb_idle_timeout" {
  type    = number
  default = 60
}

variable "security_groups" {
  description = "List of VPC SGs"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "List of subnets"
  type        = list(any)
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "deregistration_delay" {
  description = "Wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds."
  type        = number
  default     = 30
}
variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Health check interval"
  type        = number
  default     = 10
}

variable "health_check_healthy_threshold" {
  description = "Health check healthy threshold"
  type        = number
  default     = 5
}

variable "health_check_unhealthy_threshold" {
  description = "Health check unhealthy threshold"
  type        = number
  default     = 3
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN"
  type        = string
}

variable "ec2_admin_instance_id" {
  description = "BackEnd EC2 instance"
  type        = string
}
