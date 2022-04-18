variable "project" {
  type        = string
  description = "cords"
  default     = "cords"
}

variable "region" {
  type        = string
  description = "AWS N. Virginia region"
  default     = "us-east-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR"
}

variable "subnet_public_cidr_block" {
  type        = string
  description = "Public subnet CIDR"
}

variable "subnet_private_cidr_block" {
  type        = string
  description = "Private subnet CIDR"
}

