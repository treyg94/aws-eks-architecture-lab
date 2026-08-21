output "endpoint" {
  description = "Connection endpoint of the RDS instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Connection port of the RDS instance."
  value       = aws_db_instance.this.port
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "db_resource_id" {
  description = "Immutable resource ID of the RDS instance for IAM database authentication."
  value       = aws_db_instance.this.resource_id
}

output "master_secret_arn" {
  description = "ARN of the RDS-managed master credential secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "ARN of the environment-specific RDS KMS key."
  value       = aws_kms_key.this.arn
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}
