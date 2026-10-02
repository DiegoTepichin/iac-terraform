locals {
  name_prefix = "iac-${var.environment}"
}

resource "aws_vpc" "main" {
  # checkov:skip=CKV2_AWS_11:VPC Flow Logs planificados (ver README > Roadmap); se omiten hoy por costo.
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  lifecycle {
    precondition {
      condition = (
        length(var.availability_zones) >= length(var.public_subnet_cidrs) &&
        length(var.availability_zones) >= length(var.private_subnet_cidrs)
      )
      error_message = "Se requiere al menos una availability zone por cada subnet publica y privada."
    }
  }

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  # checkov:skip=CKV_AWS_130:Subnets publicas por diseno; alojan recursos que requieren IP publica.
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19:Falso positivo: la EIP esta asociada al NAT Gateway, no a una instancia EC2.
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

# Un solo NAT Gateway (en la primera AZ) por costo. Para HA real en prod se
# recomienda un NAT por AZ; ver README > Decisiones de arquitectura.
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  count = var.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${local.name_prefix}-rtb-private"
  }
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

# Sin bloques ingress/egress: Terraform elimina todas las reglas del SG por
# defecto, de modo que cualquier recurso que lo use por omision queda aislado.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-default-sg"
  }
}
