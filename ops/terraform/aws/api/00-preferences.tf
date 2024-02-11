terraform {
  required_version = ">= 1.4.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.16.0"
    }
  }

  backend "s3" {
    bucket         = "ninja-vpn-tfstate"
    key            = "api.tfstate"
    region         = "eu-west-3"
    encrypt        = true
    assume_role = {
      role_arn     = "arn:aws:iam::${local.config.aws_account}:role/provisioner"
      session_name = "ninja-vpn-api-session"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  assume_role {
    role_arn     = "arn:aws:iam::${local.config.aws_account}:role/provisioner"
    session_name = "ninja-vpn-api-session"
  }
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn     = "arn:aws:iam::${local.config.aws_account}:role/provisioner"
    session_name = "ninja-vpn-api-session"
  }

  alias = "us_east_1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}