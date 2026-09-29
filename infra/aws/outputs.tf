output "evidence_bucket" { value = aws_s3_bucket.evidence.id }
output "job_queue_url" { value = aws_sqs_queue.jobs.url }
output "lock_table" { value = aws_dynamodb_table.locks.name }
output "api_repository_url" { value = aws_ecr_repository.api.repository_url }
output "worker_repository_url" { value = aws_ecr_repository.worker.repository_url }
output "sqlserver_secret_arn" { value = aws_secretsmanager_secret.sqlserver.arn }
