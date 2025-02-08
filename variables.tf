variable "cidr_range" {
  description = "The default CIDR range to start with"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "The default VPC ID"
  type        = string
  default     = "KY-tf-VPC"
}

variable "keypair" {
  description = "The default keypair to use"
  type        = string
  default     = "ky_keypair"
}

