variable "aws_region" {
  description = "AWS region for the DBVC control plane."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Resource name prefix."
  type        = string
  default     = "dbvc"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "portfolio"
}

variable "artifact_retention_days" {
  description = "Days before noncurrent evidence objects expire."
  type        = number
  default     = 90
}
