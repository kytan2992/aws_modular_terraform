locals {
  user_data_asg = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    echo "<h1>Hello from autoscale ec2</h1>" | sudo tee /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
    EOF
}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name          = "${local.resource_prefix}-asg"
  use_name_prefix = false
  instance_name = "${local.resource_prefix}-asg-instance"

  min_size                  = 2
  max_size                  = 3
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = [""]

  traffic_source_attachments = {
    ky-alb = {
      traffic_source_identifier = module.alb.target_groups["asg_target"].arn
    }
  }

  scaling_policies = {
    my-policy = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    }
  }

  launch_template_name        = "${local.resource_prefix}-launchtemplate"
  launch_template_use_name_prefix = false
  launch_template_description = "launch template from terraform"
  update_default_version      = true

  image_id        = data.aws_ami.ami_linux.id
  instance_type   = "t2.micro"
  key_name        = var.keypair
  security_groups = [data.aws_security_group.sg.id]
  user_data       = base64encode(local.user_data_asg)

  tags = {
    Terraform = true
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "${local.resource_prefix}-alb"
  vpc_id = data.aws_vpc.vpc.id
  subnets = ["subnet-0dd44f0ba07704f84", "subnet-022318850818d68eb", "subnet-08bcb8c2c9bc9e1ac"]
  create_security_group = false
  security_groups = [data.aws_security_group.sg.id]
  enable_deletion_protection = false

  listeners = {
    ex_http = {
      port = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "asg_target"
      }
    }
  }

  target_groups = {
    asg_target = {
      name = "${local.resource_prefix}-asg-tg"
      use_name_prefix = false
      protocol = "HTTP"
      port = 80
      target_type = "instance"
      create_attachment = "false"
    }
  }
  tags = {
    Terraform = true
    name = "${local.resource_prefix}-asg-alb"
  }
}