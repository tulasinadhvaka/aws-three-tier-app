output "primary_bucket" {
  value = aws_s3_bucket.primary.id
}

output "dr_bucket" {
  value = aws_s3_bucket.dr.id
}
