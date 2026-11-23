
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}

output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "application_url" {
  value = "http://${aws_lb.app.dns_name}"
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.app.name
}

output "ecr_repository_url" {
  description = "Application ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}
output "github_actions_role_arn" {
  description = "IAM role ARN assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions_ecr.arn
}
output "monitoring_instance_id" {
  description = "Monitoring EC2 instance ID"
  value       = aws_instance.monitoring.id
}

output "monitoring_private_ip" {
  description = "Monitoring EC2 private IP"
  value       = aws_instance.monitoring.private_ip
}
