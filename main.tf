locals {
  resource_prefix = "KY-tf"
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.resource_prefix}-vpc"
  cidr = var.cidr_range

  azs             = local.azs
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr_range, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(var.cidr_range, 8, k + 4)]
  #database_subnets = [for k, v in local.azs : cidrsubnet(var.cidr_range, 8, k + 8)]

  public_subnet_names  = ["${local.resource_prefix}-public-1a", "${local.resource_prefix}-public-1b", "${local.resource_prefix}-public-1c"]
  private_subnet_names = ["${local.resource_prefix}-private-1a", "${local.resource_prefix}-private-1b", "${local.resource_prefix}-private-1c"]
  #database_subnet_names = ["${local.resource_prefix}-db-1a", "${local.resource_prefix}-db-1b", "${local.resource_prefix}-db-1c"]

  enable_dns_hostnames    = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
  }

}

module "vpc_security-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${local.resource_prefix}-SG"
  use_name_prefix = false
  description = "Security Group with HTTP, SSH and ping"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Terraform = true
  }
}
