output "staging_vpc_id" {
  description = "ID de la VPC en Staging"
  value       = module.networking.vpc_id
}

output "staging_instance_public_ip" {
  description = "IP publica de la instancia en Staging"
  value       = module.web_server.instance_public_ip
}

output "staging_instance_public_dns" {
  description = "DNS publico de la instancia en Staging"
  value       = module.web_server.instance_public_dns
}

output "staging_instance_id" {
  description = "ID de la instancia en Staging"
  value       = module.web_server.instance_id
}
