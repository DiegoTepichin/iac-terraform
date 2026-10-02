variable "environment" {
  description = "Nombre del ambiente (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment debe ser uno de: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "Bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR IPv4 valido (ej. 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Se requieren al menos 2 availability zones para alta disponibilidad."
  }
}

variable "public_subnet_cidrs" {
  description = "Lista de CIDRs para subnets públicas (una por AZ)"
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Todos los public_subnet_cidrs deben ser bloques CIDR IPv4 validos."
  }
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs para subnets privadas (una por AZ)"
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrhost(c, 0))])
    error_message = "Todos los private_subnet_cidrs deben ser bloques CIDR IPv4 validos."
  }
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para salida a internet desde subnets privadas"
  type        = bool
  default     = true
}
