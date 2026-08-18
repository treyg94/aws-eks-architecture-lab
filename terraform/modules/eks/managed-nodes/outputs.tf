output "node_group_name" {
  description = "Name of the EKS managed node group."
  value       = aws_eks_node_group.this.node_group_name
}

output "node_role_arn" {
  description = "ARN of the managed-node IAM role."
  value       = aws_iam_role.nodes.arn
}
