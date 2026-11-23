# Monitoring EC2 IAM role
resource "aws_iam_role" "monitoring" {
  name = "${var.project_name}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allow SSM management without SSH
resource "aws_iam_role_policy_attachment" "monitoring_ssm" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# Allow Prometheus EC2 service discovery
resource "aws_iam_role_policy" "monitoring_ec2_discovery" {
  name = "${var.project_name}-ec2-discovery"
  role = aws_iam_role.monitoring.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
# Monitoring instance profile
resource "aws_iam_instance_profile" "monitoring" {
  name = "${var.project_name}-monitoring-profile"
  role = aws_iam_role.monitoring.name
}

# Monitoring EC2 instance
resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.monitoring_instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 15
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/../scripts/monitoring-bootstrap.sh.tftpl", {
    prometheus_config_b64 = filebase64("${path.module}/../monitoring/prometheus/prometheus.yaml")

    grafana_datasource_b64 = filebase64("${path.module}/../monitoring/grafana/provisioning/datasources/prometheus.yaml")
  })

  tags = {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  }

  depends_on = [
    aws_iam_role_policy_attachment.monitoring_ssm,
    aws_iam_role_policy.monitoring_ec2_discovery,
    aws_route.private_nat_access
  ]
}
