variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnets_cidrs" {
  description = "Private subnet CIDR block"
  type        = list(string)
}

variable "public_subnets_cidrs" {
  description = "Public subnet CIDR block"
  type        = list(string)
}

variable "ssm_nat_eip" {
  description = "SSM path to store  nat EIPs"
  type        = string
}

