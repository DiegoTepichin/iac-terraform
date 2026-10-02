output "prod_vpc_id" {
  description = "ID de la VPC en Produccion"
  value       = module.networking.vpc_id
}

output "prod_instance_public_ip" {
  description = "IP publica de la instancia en Produccion"
  value       = module.web_server.instance_public_ip
}

output "prod_instance_public_dns" {
  description = "DNS publico de la instancia en Produccion"
  value       = module.web_server.instance_public_dns
}

output "prod_instance_id" {
  description = "ID de la instancia en Produccion"
  value       = module.web_server.instance_id
}
