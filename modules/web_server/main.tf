data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${var.environment}"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "web_sg" {
  # checkov:skip=CKV_AWS_24:Falso positivo: SSH se limita a var.my_ip, cuya validacion rechaza 0.0.0.0/0.
  # checkov:skip=CKV_AWS_260:Web server publico; HTTP desde Internet es el proposito del recurso.
  # checkov:skip=CKV_AWS_382:Egress abierto necesario para apt (paquetes y parches de seguridad).
  name        = "web-server-sg-${var.environment}"
  description = "Security group para el web server en ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH desde tu IP personal"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP de Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida a Internet (actualizaciones de paquetes)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg-${var.environment}"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = var.subnet_id
  ebs_optimized = true
  monitoring    = var.enable_detailed_monitoring

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # IMDSv2 obligatorio: mitiga robo de credenciales via SSRF.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    environment = var.environment
  })
  user_data_replace_on_change = true

  tags = {
    Name = "web-server-${var.environment}"
  }
}
