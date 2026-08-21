resource "aws_security_group" "frontend" {
  name        = "${var.name_prefix}-frontend-workload-sg"
  description = "Network identity for ${var.name_prefix} frontend workloads."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-frontend-workload-sg"
    Workload = "frontend"
  })
}

resource "aws_security_group" "backend" {
  name        = "${var.name_prefix}-backend-workload-sg"
  description = "Network identity for ${var.name_prefix} backend workloads."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name     = "${var.name_prefix}-backend-workload-sg"
    Workload = "backend"
  })
}
