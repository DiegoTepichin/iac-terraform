# Este módulo crea el backend remoto (S3 + DynamoDB) para almacenar el state de Terraform.
# Se ejecuta UNA VEZ con state local, luego los ambientes apuntan a este backend.
# El bucket y la tabla estan protegidos con prevent_destroy: perderlos implica
# perder el state de todos los ambientes.

resource "aws_s3_bucket" "terraform_state" {
  bucket = "iac-terraform-state-${random_id.suffix.hex}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  # checkov:skip=CKV_AWS_119:La tabla solo guarda LockIDs; el cifrado con llave administrada por AWS es suficiente.
  name         = "iac-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "iac-terraform-locks"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

output "state_bucket" {
  description = "Nombre del bucket S3 para el state"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table" {
  description = "Nombre de la tabla DynamoDB para locks"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "state_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.terraform_state.arn
}
