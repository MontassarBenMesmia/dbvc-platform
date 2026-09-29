# AWS Terraform starter

This module provisions the stateful security and delivery building blocks from the production reference architecture:

- customer-managed KMS key;
- private, versioned S3 evidence vault with lifecycle policy;
- DynamoDB migration lock table;
- encrypted SQS job queue and dead-letter queue;
- immutable, scan-on-push ECR repositories;
- Secrets Manager container for SQL Server credentials;
- encrypted CloudWatch log groups and a dead-letter alarm.

The VPC, Cognito, CloudFront, ALB, ECS services and RDS topology are environment-dependent and documented in `docs/aws-architecture.md`; they should be composed using an organization's approved networking modules rather than hard-coded here.

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -var environment=staging
```

Terraform deliberately creates no secret value and no RDS database by default, preventing an accidental paid deployment from a portfolio repository.
