locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Hello from private ec2</h1>" | sudo tee /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    EOF
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  for_each = toset(["one", "two"])

  name = "${local.resource_prefix}-instance-${each.key}"

  ami                         = data.aws_ami.ami_linux.id
  instance_type               = "t2.micro"
  key_name                    = var.keypair
  vpc_security_group_ids      = [data.aws_security_group.sg.id]
  subnet_id                   = slice(module.vpc.public_subnets, 0, 3)
  associate_public_ip_address = true
  user_data_base64            = base64encode(local.user_data)

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}