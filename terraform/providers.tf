terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.44.0"
    }
  }

  cloud {
    organization = "thusiru-dev"
    workspaces {
      name = "eks-microservices"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "ap-southeast-1"
}
