data "aws_caller_identity" "current" {}

locals {
  prefix = "${var.project_name}-${var.environment}"
}

resource "aws_kms_key" "evidence" {
  description             = "Encrypt DBVC migration evidence"
  deletion_window_in_days = 14
  enable_key_rotation     = true
}

resource "aws_kms_alias" "evidence" {
  name          = "alias/${local.prefix}-evidence"
  target_key_id = aws_kms_key.evidence.key_id
}

resource "aws_s3_bucket" "evidence" {
  bucket = "${local.prefix}-evidence-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket                  = aws_s3_bucket.evidence.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.evidence.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  rule {
    id     = "archive-evidence"
    status = "Enabled"
    filter {}
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = var.artifact_retention_days
    }
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "${local.prefix}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "lock_id"
  attribute {
    name = "lock_id"
    type = "S"
  }
  point_in_time_recovery { enabled = true }
  server_side_encryption { enabled = true }
}

resource "aws_sqs_queue" "dead_letter" {
  name                      = "${local.prefix}-jobs-dlq"
  kms_master_key_id         = "alias/aws/sqs"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "jobs" {
  name                       = "${local.prefix}-jobs"
  kms_master_key_id          = "alias/aws/sqs"
  visibility_timeout_seconds = 900
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 3
  })
}

resource "aws_ecr_repository" "api" {
  name                 = "${local.prefix}/api"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

resource "aws_ecr_repository" "worker" {
  name                 = "${local.prefix}/worker"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }
}

resource "aws_secretsmanager_secret" "sqlserver" {
  name                    = "${local.prefix}/sqlserver"
  description             = "SQL Server connection material populated outside Terraform"
  kms_key_id              = aws_kms_key.evidence.arn
  recovery_window_in_days = 14
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.prefix}/api"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.evidence.arn
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${local.prefix}/worker"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.evidence.arn
}

resource "aws_cloudwatch_metric_alarm" "dead_letter_messages" {
  alarm_name          = "${local.prefix}-dead-letter-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "A DBVC job exhausted its retries."
  dimensions = {
    QueueName = aws_sqs_queue.dead_letter.name
  }
}
