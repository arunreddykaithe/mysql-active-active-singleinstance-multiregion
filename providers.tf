terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Primary region provider
provider "aws" {
  alias  = "region1"
  region = var.region1
  
  default_tags {
    tags = {
      Project     = "MySQL-Active-Active"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.region1
    }
  }
}

# Secondary region provider
provider "aws" {
  alias  = "region2"
  region = var.region2
  
  default_tags {
    tags = {
      Project     = "MySQL-Active-Active"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Region      = var.region2
    }
  }
}

# Random provider for UUID generation
provider "random" {}
