output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "HTTP URL of the application."
  value       = "http://${aws_lb.this.dns_name}"
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "app_security_group_id" {
  description = "Security group ID of the application instances."
  value       = aws_security_group.app.id
}

output "iam_role_name" {
  description = "IAM role attached to the instances, for attaching extra policies."
  value       = aws_iam_role.app.name
}
