data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_security_group" "sg" {
  id = module.vpc_security-group.security_group_id
}

data "aws_vpc" "vpc" {
  id = module.vpc.default_vpc_id

}

data "aws_ami" "ami_linux" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}