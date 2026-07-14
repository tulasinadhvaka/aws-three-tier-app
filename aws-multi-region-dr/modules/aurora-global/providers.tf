terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # aws     -> primary region
      # aws.dr  -> DR region
      configuration_aliases = [aws, aws.dr]
    }
  }
}
