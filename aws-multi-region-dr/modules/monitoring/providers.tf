terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Route 53 health-check metrics are only published in us-east-1,
      # so the alarm must be created with a us-east-1 provider.
      configuration_aliases = [aws, aws.useast1]
    }
  }
}
