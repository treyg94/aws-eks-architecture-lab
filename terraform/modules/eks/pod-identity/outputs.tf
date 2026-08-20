output "role_arns" {
  description = "IAM role ARNs keyed by workload identity name."
  value       = { for name, role in aws_iam_role.this : name => role.arn }
}
