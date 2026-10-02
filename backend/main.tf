# Bootstrap stack for the remote state backend (S3 + DynamoDB).
# It is applied ONCE with local state; the environments then point at it.
# Bucket and table use prevent_destroy: losing them means losing the state of
# every environment.

resource "aws_s3_bucket" "terraform_state" {
  # checkov:skip=CKV_AWS_18:Access logging needs a second bucket; out of scope for a single-user state bucket.
  # checkov:skip=CKV_AWS_144:Cross-region replication is unnecessary; versioning covers state recovery.
  # checkov:skip=CKV2_AWS_62:Nothing consumes state write events.
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
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Keep the last 10 noncurrent state versions for 90 days: enough to recover a
# corrupted state without accumulating versions forever.
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 10
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.terraform_state]
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  # checkov:skip=CKV_AWS_119:The table only stores lock IDs; the AWS managed key is sufficient.
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
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table" {
  description = "Name of the DynamoDB table used for state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "state_bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.terraform_state.arn
}
