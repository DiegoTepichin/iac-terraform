terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Tags comunes aplicados a todos los recursos (costos y trazabilidad).
  default_tags {
    tags = {
      Project     = "iac-terraform"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
