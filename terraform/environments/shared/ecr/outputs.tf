output "repository_name" {
  description = "Name of the shared application ECR repository."
  value       = module.ecr.repository_name
}

output "repository_arn" {
  description = "ARN of the shared application ECR repository."
  value       = module.ecr.repository_arn
}

output "repository_url" {
  description = "URL used to push and pull application images."
  value       = module.ecr.repository_url
}

output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key used to encrypt ECR images."
  value       = module.ecr.kms_key_arn
}

output "kms_alias" {
  description = "Friendly alias of the ECR KMS key."
  value       = module.ecr.kms_alias
}
