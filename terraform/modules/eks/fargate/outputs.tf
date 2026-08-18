output "profile_names" {
  description = "Names of the EKS Fargate profiles."
  value       = keys(aws_eks_fargate_profile.this)
}

output "pod_execution_role_arn" {
  description = "ARN of the Fargate pod execution IAM role."
  value       = aws_iam_role.pod_execution.arn
}
