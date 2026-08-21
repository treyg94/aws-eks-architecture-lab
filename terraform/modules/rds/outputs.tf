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

output "master_secret_arn" {
  description = "ARN of the RDS-managed master credential secret."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "ARN of the environment-specific RDS KMS key."
  value       = aws_kms_key.this.arn
}

output "backend_workload_security_group_id" {
  description = "ID of the security group reserved for backend workloads."
  value       = aws_security_group.backend_workload.id
}

output "frontend_workload_security_group_id" {
  description = "ID of the security group reserved for frontend workloads."
  value       = aws_security_group.frontend_workload.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}
