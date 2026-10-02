output "instance_public_ip" {
  description = "IP publica de la instancia EC2"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "DNS publico de la instancia EC2"
  value       = aws_instance.web.public_dns
}

output "instance_id" {
  description = "El ID de la instancia"
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "ID del security group del web server"
  value       = aws_security_group.web_sg.id
}

output "iam_role_name" {
  description = "Nombre del IAM role de la instancia (para adjuntar politicas adicionales)"
  value       = aws_iam_role.web.name
}
