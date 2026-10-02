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
}

variables {
  environment     = "staging"
  instance_type   = "t3.small"
  public_key_path = "./tests/fixtures/test_key.pub"
  my_ip           = "203.0.113.50/32"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_id       = "subnet-0123456789abcdef0"
}

run "honors_instance_type" {
  command = plan

  assert {
    condition     = aws_instance.web.instance_type == "t3.small"
    error_message = "La instancia debe usar var.instance_type."
  }
}

run "enforces_imdsv2_and_encryption" {
  command = plan

  assert {
    condition     = aws_instance.web.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 debe ser obligatorio."
  }

  assert {
    condition     = aws_instance.web.root_block_device[0].encrypted == true
    error_message = "El volumen raiz debe estar cifrado."
  }
}

run "restricts_ssh_to_my_ip" {
  command = plan

  assert {
    condition = anytrue([
      for rule in aws_security_group.web_sg.ingress :
      rule.from_port == 22 && rule.cidr_blocks == tolist(["203.0.113.50/32"])
    ])
    error_message = "SSH debe limitarse a var.my_ip."
  }
}

run "rejects_ssh_open_to_world" {
  command = plan

  variables {
    my_ip = "0.0.0.0/0"
  }

  expect_failures = [var.my_ip]
}

run "attaches_ssm_instance_profile" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.ssm_core.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    error_message = "La instancia debe tener la politica de SSM para administracion sin SSH."
  }
}
