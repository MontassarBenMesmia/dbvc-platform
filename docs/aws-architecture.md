# AWS production reference architecture

This architecture is a deployment design, not a claim that the public demo currently runs the paid production topology.

```mermaid
flowchart LR
    User[Operator] --> WAF[AWS WAF]
    WAF --> CF[CloudFront]
    CF --> Web[S3 Angular origin]
    User --> Cognito[Amazon Cognito]
    CF --> ALB[Application Load Balancer]
    ALB --> API[ECS Fargate API]
    API --> SQS[SQS migration jobs]
    SQS --> Worker[ECS Fargate worker\nPowerShell 7 + sqlcmd]
    Worker --> RDS[(RDS for SQL Server)]
    Worker --> Evidence[S3 evidence vault]
    Worker --> Lock[(DynamoDB locks)]
    Worker --> Secrets[Secrets Manager]
    Evidence --> KMS[AWS KMS]
    API --> CW[CloudWatch]
    Worker --> CW
    API --> Trail[CloudTrail]
    GitHub[GitHub Actions OIDC] --> ECR[Amazon ECR]
    ECR --> API
    ECR --> Worker
```

## Network

- CloudFront, WAF, and the ALB form the public ingress path.
- API tasks run in private application subnets; workers and RDS run in isolated data subnets.
- Workers reach AWS services through VPC endpoints and reach SQL Server only on TCP 1433 through a dedicated security group.
- NAT is optional when all image, log, secret, queue, and artifact traffic uses endpoints.

## Identity and secrets

- Cognito issues user tokens; the API maps groups to read, verify, approve, and apply permissions.
- GitHub Actions assumes a narrowly scoped deployment role through OIDC—no long-lived AWS keys.
- SQL credentials live in Secrets Manager and are fetched only by the worker task role.
- KMS keys separate artifact encryption from log encryption.

## Execution and recovery

1. API validates metadata and writes an immutable plan to the evidence bucket.
2. API creates an idempotent job and sends its identifier to SQS.
3. Worker takes a DynamoDB lock scoped to environment and database.
4. Verify runs in a transaction and rolls back. Apply additionally creates a SQL Server backup.
5. Worker uploads manifests, checksums, logs, and results to versioned S3 storage.
6. CloudWatch alarms on failed jobs, queue age, task failures, and unhealthy targets; CloudTrail records control-plane actions.

## Availability and cost controls

- Multi-AZ RDS and multiple worker tasks are production options, not required for the portfolio demo.
- SQS redrive sends repeatedly failing jobs to a dead-letter queue.
- S3 lifecycle rules move old evidence to Glacier and expire noncurrent demo versions.
- ECS services can scale to zero in non-production environments.
