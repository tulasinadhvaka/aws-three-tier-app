# Remote state backend.
# Bootstrap the bucket + lock table once (see README), then fill in real names below.
# Left commented so `terraform init` works locally before you wire up remote state.

# terraform {
#   backend "s3" {
#     bucket         = "my-tf-state-<account-id>"
#     key            = "aws-terraform-foundation/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "tf-state-lock"
#     encrypt        = true
#   }
# }
