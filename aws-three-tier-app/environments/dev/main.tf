terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "aws-three-tier-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "alb" {
  source            = "../../modules/alb"
  name              = var.environment
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  app_port          = var.app_port
}

module "app" {
  source                = "../../modules/app"
  name                  = var.environment
  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  app_port              = var.app_port
  instance_count        = var.instance_count
  instance_profile_name = var.instance_profile_name
}

module "database" {
  source                = "../../modules/database"
  name                  = var.environment
  vpc_id                = var.vpc_id
  private_subnet_ids    = var.private_subnet_ids
  app_security_group_id = module.app.app_security_group_id
  db_password           = var.db_password
  multi_az              = var.db_multi_az
}
