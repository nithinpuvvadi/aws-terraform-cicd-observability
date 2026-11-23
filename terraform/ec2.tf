
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 10
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }


  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euxo pipefail

  exec > >(tee -a /var/log/user-data.log) 2>&1

  # Install and start Docker
  dnf install -y docker
  systemctl enable --now docker

  # Authenticate to Amazon ECR using the EC2 instance role
  aws ecr get-login-password --region ${var.aws_region} \
    | docker login \
      --username AWS \
      --password-stdin ${aws_ecr_repository.app.repository_url}

  # Pull the immutable application image
  docker pull ${aws_ecr_repository.app.repository_url}:${var.image_tag}

  # Start the application container
  docker run -d \
    --name aws-devops-demo \
    --restart unless-stopped \
    -p 5000:5000 \
    ${aws_ecr_repository.app.repository_url}:${var.image_tag}
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-app"
      Role = "app"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.project_name}-app-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-asg"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = aws_subnet.private[*].id

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  health_check_type         = "ELB"
  health_check_grace_period = 240

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app"
    propagate_at_launch = true
  }
  tag {
    key                 = "Role"
    value               = "app"
    propagate_at_launch = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core,
    aws_iam_role_policy_attachment.ecr_pull,
    aws_route.private_nat_access
  ]
}

