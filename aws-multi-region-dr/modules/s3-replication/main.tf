locals {
  tags         = merge(var.tags, { Module = "s3-replication" })
  primary_name = "${var.name_prefix}-primary-${var.bucket_suffix}"
  dr_name      = "${var.name_prefix}-dr-${var.bucket_suffix}"
}

# --- Destination (DR) bucket ---
resource "aws_s3_bucket" "dr" {
  provider = aws.dr
  bucket   = local.dr_name
  tags     = local.tags
}

resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket   = aws_s3_bucket.dr.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- Source (primary) bucket ---
resource "aws_s3_bucket" "primary" {
  bucket = local.primary_name
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled" # CRR requires versioning on both buckets
  }
}

# --- IAM role S3 uses to replicate ---
data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "${var.name_prefix}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.primary.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resources = ["${aws_s3_bucket.primary.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resources = ["${aws_s3_bucket.dr.arn}/*"]
  }
}

resource "aws_iam_role_policy" "replication" {
  name   = "${var.name_prefix}-s3-replication"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

# --- Replication configuration on the source bucket ---
resource "aws_s3_bucket_replication_configuration" "this" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.dr.arn
      storage_class = "STANDARD"
    }
  }

  # Replication config depends on versioning being enabled first.
  depends_on = [aws_s3_bucket_versioning.primary]
}
