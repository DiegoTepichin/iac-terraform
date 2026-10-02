variable "environment" {
  description = "El ambiente (ej. dev, prod)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia de EC2 a levantar"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Ruta a la llave publica para SSH"
  type        = string
}

variable "my_ip" {
  description = "Tu IP publica en notacion CIDR para permitir SSH. Ej: 203.0.113.50/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip, 0)) && var.my_ip != "0.0.0.0/0"
    error_message = "my_ip debe ser un CIDR valido y no puede ser 0.0.0.0/0 (SSH abierto a Internet). Usa tu IP publica con /32."
  }
}

variable "vpc_id" {
  description = "ID de la VPC donde crear el Security Group"
  type        = string
}

variable "subnet_id" {
  description = "ID de la subnet donde lanzar la instancia EC2"
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "Habilita CloudWatch detailed monitoring (metricas cada 1 min, con costo adicional)"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Tamano del volumen raiz en GiB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size debe ser de al menos 8 GiB (minimo de la AMI de Ubuntu)."
  }
}
