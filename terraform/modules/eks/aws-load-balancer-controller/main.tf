resource "aws_iam_policy" "this" {
  name        = var.policy_name
  description = "Permissions required by AWS Load Balancer Controller v3.3.0."
  policy      = file("${path.module}/iam-policy.json")
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = var.role_name
  policy_arn = aws_iam_policy.this.arn
}
