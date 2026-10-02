variable "aws_region" {
  description = "Region de AWS donde vamos a desplegar"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nombre del ambiente (ej. dev)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser uno de: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "Tipo de instancia de EC2 a levantar"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Ruta a la llave publica para SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_ip" {
  description = "Tu IP publica en notacion CIDR para permitir SSH. Ej: 203.0.113.50/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0)) && var.my_ip != "0.0.0.0/0"
    error_message = "my_ip debe ser un CIDR valido y no puede ser 0.0.0.0/0. Usa tu IP publica con /32 (curl -s ifconfig.me)."
  }
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para desplegar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs para las subnets publicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs para las subnets privadas"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway en dev (false para ahorrar costos)"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Habilita CloudWatch detailed monitoring en la instancia EC2"
  type        = bool
  default     = false
}
