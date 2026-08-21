output "role_arns" {
  description = "IAM role ARNs keyed by workload identity name."
  value       = { for name, role in aws_iam_role.this : name => role.arn }
}

output "role_names" {
  description = "IAM role names keyed by workload identity name."
  value       = { for name, role in aws_iam_role.this : name => role.name }
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider used for IRSA."
  value       = aws_iam_openid_connect_provider.this.arn
}
