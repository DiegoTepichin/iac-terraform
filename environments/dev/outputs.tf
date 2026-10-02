output "dev_vpc_id" {
  description = "ID de la VPC en Dev"
  value       = module.networking.vpc_id
}

output "dev_instance_public_ip" {
  description = "IP publica de la instancia en Dev"
  value       = module.web_server.instance_public_ip
}

output "dev_instance_public_dns" {
  description = "DNS publico de la instancia en Dev"
  value       = module.web_server.instance_public_dns
}

output "dev_instance_id" {
  description = "ID de la instancia en Dev"
  value       = module.web_server.instance_id
}
