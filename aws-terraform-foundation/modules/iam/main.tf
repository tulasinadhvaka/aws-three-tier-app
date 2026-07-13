locals {
  tags = merge(var.tags, { Module = "iam", Environment = var.name })
}

# Baseline role EC2 instances can assume — least-privilege starting point.
# Attach further policies as workloads require them, rather than granting broad access.
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_baseline" {
  name               = "${var.name}-ec2-baseline"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

# SSM access lets you manage instances without opening SSH (port 22) to the world.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_baseline.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_baseline" {
  name = "${var.name}-ec2-baseline"
  role = aws_iam_role.ec2_baseline.name
  tags = local.tags
}
