resource "aws_kms_key" "this" {
  description             = "Encrypts the ${var.identifier} RDS instance and its managed master secret."
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_in_days

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.kms_alias_name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.identifier}-rds-sg"
  description = "PostgreSQL access to the ${var.identifier} RDS instance."
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.identifier}-rds-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "backend_to_rds" {
  security_group_id            = var.backend_workload_security_group_id
  referenced_security_group_id = aws_security_group.rds.id
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port

  description = "Allow the backend workload to reach PostgreSQL."
}

resource "aws_vpc_security_group_ingress_rule" "backend_to_rds" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.backend_workload_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port

  description = "Allow PostgreSQL from the dedicated backend workload security group."
}

resource "aws_vpc_security_group_ingress_rule" "operator_to_rds" {
  for_each = toset(var.operator_access_cidrs)

  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.port
  to_port           = var.port

  description = "Allow PostgreSQL from an approved operator CIDR."
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine                      = "postgres"
  engine_version              = var.engine_version
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  instance_class        = var.instance_class
  storage_type          = var.storage_type
  allocated_storage     = var.allocated_storage
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.this.arn
  max_allocated_storage = 0

  username                            = var.master_username
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = aws_kms_key.this.arn
  iam_database_authentication_enabled = true

  port                   = var.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = false

  backup_retention_period   = var.backup_retention_period
  deletion_protection       = false
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.identifier}-final-${formatdate("YYYYMMDDhhmmss", plantimestamp())}"
  copy_tags_to_snapshot     = true

  tags = var.tags

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
