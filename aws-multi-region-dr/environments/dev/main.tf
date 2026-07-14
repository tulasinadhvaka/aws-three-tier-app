terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "${var.environment}-dr"
}

# --- Providers: primary, DR, and a dedicated us-east-1 for Route53/CloudFront metrics ---
provider "aws" {
  region = var.primary_region
  default_tags {
    tags = { Project = "aws-dr-multiregion", Environment = var.environment, ManagedBy = "terraform" }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
  default_tags {
    tags = { Project = "aws-dr-multiregion", Environment = var.environment, ManagedBy = "terraform" }
  }
}

# Route 53 health-check metrics + CloudFront live in us-east-1.
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
  default_tags {
    tags = { Project = "aws-dr-multiregion", Environment = var.environment, ManagedBy = "terraform" }
  }
}

# --- Networking in both regions (same module, two provider configs) ---
module "network_primary" {
  source      = "../../modules/network"
  name_prefix = "${local.name_prefix}-primary"
  cidr_block  = var.primary_cidr
}

module "network_dr" {
  source      = "../../modules/network"
  name_prefix = "${local.name_prefix}-dr"
  cidr_block  = var.dr_cidr
  providers = {
    aws = aws.dr
  }
}

# --- ALB in both regions ---
module "alb_primary" {
  source            = "../../modules/alb"
  name_prefix       = "${local.name_prefix}-primary"
  vpc_id            = module.network_primary.vpc_id
  public_subnet_ids = module.network_primary.public_subnet_ids
}

module "alb_dr" {
  source            = "../../modules/alb"
  name_prefix       = "${local.name_prefix}-dr"
  vpc_id            = module.network_dr.vpc_id
  public_subnet_ids = module.network_dr.public_subnet_ids
  providers = {
    aws = aws.dr
  }
}

# --- Data tier: Aurora Global + Redis Global ---
module "aurora" {
  source             = "../../modules/aurora-global"
  name_prefix        = local.name_prefix
  master_password    = var.db_master_password
  primary_subnet_ids = module.network_primary.private_subnet_ids
  dr_subnet_ids      = module.network_dr.private_subnet_ids
  primary_vpc_id     = module.network_primary.vpc_id
  dr_vpc_id          = module.network_dr.vpc_id
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
}

module "redis" {
  source             = "../../modules/redis-global"
  name_prefix        = local.name_prefix
  primary_subnet_ids = module.network_primary.private_subnet_ids
  dr_subnet_ids      = module.network_dr.private_subnet_ids
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
}

# --- S3 cross-region replication ---
module "s3" {
  source        = "../../modules/s3-replication"
  name_prefix   = local.name_prefix
  bucket_suffix = var.bucket_suffix
  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
}

# --- Edge: CloudFront origin-group failover ---
module "cloudfront" {
  source                = "../../modules/cloudfront"
  name_prefix           = local.name_prefix
  primary_origin_domain = module.alb_primary.alb_dns_name
  dr_origin_domain      = module.alb_dr.alb_dns_name
}

# --- DNS failover ---
module "route53" {
  source              = "../../modules/route53"
  name_prefix         = local.name_prefix
  hosted_zone_id      = var.hosted_zone_id
  record_name         = var.record_name
  primary_alb_dns     = module.alb_primary.alb_dns_name
  primary_alb_zone_id = module.alb_primary.alb_zone_id
  dr_alb_dns          = module.alb_dr.alb_dns_name
  dr_alb_zone_id      = module.alb_dr.alb_zone_id
}

# --- Monitoring / alarms ---
module "monitoring" {
  source                  = "../../modules/monitoring"
  name_prefix             = local.name_prefix
  primary_health_check_id = module.route53.primary_health_check_id
  notification_email      = var.notification_email
  providers = {
    aws         = aws
    aws.useast1 = aws.useast1
  }
}
