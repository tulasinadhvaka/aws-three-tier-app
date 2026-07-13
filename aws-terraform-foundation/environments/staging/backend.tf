# Remote state backend for staging.
# Bootstrap the bucket + lock table once (see README), then uncomment and fill in real names.

# terraform {
#   backend "s3" {
#     bucket         = "my-tf-state-<account-id>"
#     key            = "aws-terraform-foundation/staging/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "tf-state-lock"
#     encrypt        = true
#   }
# }
