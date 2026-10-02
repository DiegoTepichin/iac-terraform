terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every resource for cost allocation and traceability.
  default_tags {
    tags = {
      Project     = "iac-terraform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
