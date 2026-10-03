output "app_url" {
  description = "HTTP URL of the application load balancer."
  value       = module.web_app.app_url
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = module.web_app.alb_dns_name
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group running the application."
  value       = module.web_app.autoscaling_group_name
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.networking.vpc_id
}
