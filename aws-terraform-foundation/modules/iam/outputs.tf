output "ec2_role_arn" {
  description = "ARN of the baseline EC2 IAM role."
  value       = aws_iam_role.ec2_baseline.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the baseline EC2 instance profile."
  value       = aws_iam_instance_profile.ec2_baseline.name
}
