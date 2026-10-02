# NOTA: Antes de usar remote state, ejecuta 'backend/' para crear S3 + DynamoDB.
# Luego reemplaza 'bucket' con el nombre del bucket creado.
# terraform init -reconfigure

terraform {
  backend "s3" {
    bucket         = "REEMPLAZAR_CON_NOMBRE_DEL_BUCKET"
    key            = "env/staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "iac-terraform-locks"
  }
}
