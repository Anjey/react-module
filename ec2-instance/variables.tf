# variable "name" {
#   description = "Resource name (used as prefix)"
#   type        = string
# }

variable "instance_name" {
  description = "Instance name"
  type        = string
}

variable "instance_count" {
  description = "Number of frontend EC2 instances to deploy"
  type        = number
}

variable "ami" {
  description = "AMI to start instance from"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key name to access an instances"
  type        = string
}

variable "iam_instance_profile" {
  description = "EC2 profile"
  type        = string
  default     = null
}

variable "subnets_ids" {
  description = "Subnets IDs in VPC"
  type        = list(any)
}

variable "root_volume_size" {
  description = "Root block device size"
  type        = number
}

variable "associate_public_ip_address" {
  description = "Associate default public ip address"
  type        = bool
  default     = false
}

variable "associate_elastic_ip_address" {
  description = "Associate EIP address to the instance"
  type        = bool
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# variable "sns_topic_arn" {
#   description = "SNS topic for alerts"
#   type        = string
# }

variable "vpc_security_group_ids" {
  description = "List of VPC SGs"
  type        = list(string)
  default     = []
}
