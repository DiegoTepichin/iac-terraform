# Runs entirely against a mocked AWS provider: no credentials, no real resources.
mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/test"
    }
  }

  mock_resource "aws_launch_template" {
    defaults = {
      id = "lt-0123456789abcdef0"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test/0123456789abcdef"
    }
  }
}

variables {
  environment        = "staging"
  vpc_id             = "vpc-0123456789abcdef0"
  public_subnet_ids  = ["subnet-0000000000000000a", "subnet-0000000000000000b"]
  private_subnet_ids = ["subnet-0000000000000000c", "subnet-0000000000000000d"]
  instance_type      = "t3.small"
  min_size           = 2
  desired_capacity   = 2
  max_size           = 4
}

run "instances_run_in_private_subnets" {
  command = plan

  assert {
    condition     = toset(aws_autoscaling_group.app.vpc_zone_identifier) == toset(var.private_subnet_ids)
    error_message = "The Auto Scaling Group must launch instances only in the private subnets."
  }

  assert {
    condition     = toset(aws_lb.this.subnets) == toset(var.public_subnet_ids)
    error_message = "The load balancer must live in the public subnets."
  }
}

run "launch_template_is_hardened" {
  command = plan

  assert {
    condition     = aws_launch_template.app.instance_type == "t3.small"
    error_message = "The launch template must use var.instance_type."
  }

  assert {
    condition     = aws_launch_template.app.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }

  assert {
    condition     = aws_launch_template.app.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "The root volume must be encrypted."
  }

  assert {
    condition     = aws_launch_template.app.key_name == null
    error_message = "Instances must not have an SSH key pair; access is through SSM."
  }
}

run "instances_accept_traffic_only_from_alb" {
  command = apply

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_alb.referenced_security_group_id == aws_security_group.alb.id
    error_message = "Application instances must only accept traffic from the ALB security group."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.app_from_alb.from_port == 80 && aws_vpc_security_group_ingress_rule.app_from_alb.to_port == 80
    error_message = "The only ingress to the instances must be HTTP (port 80) from the ALB."
  }
}

run "health_checks_come_from_the_load_balancer" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.app.health_check_type == "ELB"
    error_message = "The ASG must replace instances that fail ALB health checks."
  }
}

run "rejects_inconsistent_capacity" {
  command = plan

  variables {
    min_size         = 3
    desired_capacity = 2
    max_size         = 4
  }

  expect_failures = [aws_autoscaling_group.app]
}

run "rejects_single_public_subnet" {
  command = plan

  variables {
    public_subnet_ids = ["subnet-0000000000000000a"]
  }

  expect_failures = [var.public_subnet_ids]
}

run "rejects_invalid_cpu_target" {
  command = plan

  variables {
    cpu_target_percent = 0
  }

  expect_failures = [var.cpu_target_percent]
}
