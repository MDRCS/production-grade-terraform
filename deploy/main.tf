terraform {
  backend "s3" {
    bucket         = "django-rest-api-devops-tfstate"
    key            = "django-rest-api.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "django-rest-api-devops-tf-state-lock"
  }
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 4.49.0"
}

# dynamic variables
locals {
  prefix = "${var.prefix}-${terraform.workspace}"
  common_tags = {
    Environment = terraform.workspace
    Project     = var.project
    Owner       = var.contact
    ManagedBy   = "Terraform"
  }
}

data "aws_region" "current" {} # data to retrieve region that we are deploying to