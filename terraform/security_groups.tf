
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP traffic to the application load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow application traffic only from ALB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow Flask traffic from ALB only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 5000
  to_port                      = 5000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  description       = "Allow outbound traffic for updates and SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Security group for Prometheus and Grafana monitoring host
resource "aws_security_group" "monitoring" {
  name        = "aws-devops-demo-monitoring-sg"
  description = "Security group for Prometheus and Grafana"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "aws-devops-demo-monitoring-sg"
  }
}

# Allow monitoring host to scrape application metrics
resource "aws_vpc_security_group_ingress_rule" "app_from_monitoring" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.monitoring.id

  ip_protocol = "tcp"
  from_port   = 5000
  to_port     = 5000

  description = "Allow Prometheus to scrape Flask application metrics"
}

# Allow monitoring host outbound communication
resource "aws_vpc_security_group_egress_rule" "monitoring_egress" {
  security_group_id = aws_security_group.monitoring.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic for SSM and image downloads"
}
