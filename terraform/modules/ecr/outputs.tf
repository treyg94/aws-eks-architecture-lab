output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL used to push and pull images from the ECR repository."
  value       = aws_ecr_repository.this.repository_url
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used to encrypt ECR images."
  value       = aws_kms_key.this.arn
}

output "kms_alias" {
  description = "Friendly alias of the ECR KMS key."
  value       = aws_kms_alias.this.name
}
