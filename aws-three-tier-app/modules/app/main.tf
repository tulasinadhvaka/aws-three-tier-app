locals {
  tags = merge(var.tags, { Module = "app", Tier = "app" })
}

# Latest Amazon Linux 2023 AMI.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# App security group: only the ALB may reach the app port.
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Allow app-port traffic only from the ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "All outbound (updates, DB, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.name}-app-sg" })
}

# Minimal user-data: a static page so ALB health checks pass out of the box.
# Replace with your real app bootstrap for production.
locals {
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y python3
    cat > /tmp/index.html <<'HTML'
    <h1>${var.name} app tier</h1><p>Served from a private subnet via the ALB.</p>
    HTML
    cd /tmp && nohup python3 -m http.server ${var.app_port} >/dev/null 2>&1 &
  EOF
  )
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type
  user_data     = local.user_data

  vpc_security_group_ids = [aws_security_group.app.id]

  dynamic "iam_instance_profile" {
    for_each = var.instance_profile_name == "" ? [] : [1]
    content {
      name = var.instance_profile_name
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${var.name}-app" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.name}-app-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"

  min_size         = 1
  max_size         = var.instance_count + 1
  desired_capacity = var.instance_count

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
}
