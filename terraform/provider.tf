terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  backend "s3" {
    bucket       = "aws-terraform-cicd-observability-tfstate-470527513869"
    key          = "environments/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "demo"
      ManagedBy   = "Terraform"
    }
  }
}
