# ---------------- AMI: Packer golden image, or stock Amazon Linux 2023 ----------------

data "aws_ami" "golden" {
  count = var.use_golden_ami ? 1 : 0

  owners      = ["self"]
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.golden_ami_name_prefix}*"]
  }
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami_id = var.use_golden_ami ? data.aws_ami.golden[0].id : nonsensitive(data.aws_ssm_parameter.al2023.value)
}

# ---------------- Security group ----------------

resource "aws_security_group" "app" {
  name        = "sg-app-${local.name}"
  description = "Web instances: HTTP from the ALB only"
  vpc_id      = aws_vpc.this.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  #checkov:skip=CKV_AWS_260:False positive: source is the ALB security group, not 0.0.0.0/0
  security_group_id            = aws_security_group.app.id
  description                  = "HTTP from the ALB"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out (package repos, SSM) via NAT"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_http_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP out (package mirrors) via NAT"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------------- IAM: SSM Session Manager instead of SSH keys ----------------

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "app-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "app-${local.name}"
  role = aws_iam_role.app.name
  tags = local.tags
}

# ---------------- Launch template + Auto Scaling group ----------------

resource "aws_launch_template" "app" {
  name_prefix   = "lt-${local.name}-"
  image_id      = local.ami_id
  instance_type = var.instance_type
  ebs_optimized = true

  user_data = var.use_golden_ami ? null : base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    project     = var.project
    environment = var.environment
  }))

  vpc_security_group_ids = [aws_security_group.app.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "web-${local.name}" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tags = local.tags
}

resource "aws_autoscaling_group" "app" {
  name                      = "asg-${local.name}"
  vpc_zone_identifier       = aws_subnet.private[*].id
  min_size                  = var.asg_min_size
  desired_capacity          = var.asg_desired_capacity
  max_size                  = var.asg_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 120
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # A new AMI or user data rolls the instances automatically
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(local.tags, { Name = "web-${local.name}" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
