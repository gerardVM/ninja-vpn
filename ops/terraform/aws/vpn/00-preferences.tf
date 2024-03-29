terraform {
  required_version = "~>1.4.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16.0"
    }
  }

  backend "s3" {
    bucket         = "ninja-vpn-tfstate"
    dynamodb_table = "ninja-vpn-tfstate-lock"
    region         = "eu-west-3"
    encrypt        = true
  }
}

provider "aws" {
  region = local.config.region
}

provider "aws" {
  region = local.config.api_region
  
  alias  = "api_infra"
}
