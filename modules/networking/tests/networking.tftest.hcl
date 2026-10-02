# Runs entirely against a mocked AWS provider: no credentials, no real resources.
mock_provider "aws" {}

variables {
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

run "creates_one_subnet_per_cidr" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected two public and two private subnets."
  }
}

run "nat_disabled_creates_no_nat_resources" {
  command = plan

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 0 && length(aws_eip.nat) == 0
    error_message = "With enable_nat_gateway = false there must be no NAT Gateway or EIP."
  }
}

run "nat_enabled_routes_private_subnets" {
  command = plan

  variables {
    enable_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.main) == 1 && length(aws_route_table_association.private) == 2
    error_message = "With NAT enabled, every private subnet must use the private route table."
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [var.environment]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vpc_cidr = "10.0.0.0/33"
  }

  expect_failures = [var.vpc_cidr]
}

run "rejects_more_subnets_than_azs" {
  command = plan

  variables {
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  }

  expect_failures = [aws_vpc.main]
}
