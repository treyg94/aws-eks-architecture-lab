variable "identifier" {
  description = "Identifier for the RDS instance and its supporting resources."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL major engine version."
  type        = string
}

variable "instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"
}

variable "allocated_storage" {
  description = "Allocated RDS storage in GiB."
  type        = number
  default     = 30
}

variable "master_username" {
  description = "Master database username whose password is managed by RDS."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the RDS instance."
  type        = string
}

variable "backend_workload_security_group_id" {
  description = "ID of the application-owned backend workload security group allowed to reach PostgreSQL."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by the DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS requires at least two subnets in its DB subnet group."
  }
}

variable "publicly_accessible" {
  description = "Whether the RDS instance receives a publicly resolvable endpoint."
  type        = bool
  default     = false
}

variable "operator_access_cidrs" {
  description = "Operator IPv4 CIDRs allowed direct PostgreSQL access."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.operator_access_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Operator access values must be valid IPv4 CIDRs and cannot include 0.0.0.0/0."
  }
}

variable "port" {
  description = "PostgreSQL listener port."
  type        = number
  default     = 5432
}

variable "backup_retention_period" {
  description = "Number of days automated backups are retained."
  type        = number
  default     = 1
}

variable "kms_alias_name" {
  description = "Friendly KMS alias name without the alias/ prefix."
  type        = string

  validation {
    condition     = length(var.kms_alias_name) > 0 && !startswith(var.kms_alias_name, "alias/")
    error_message = "The KMS alias name must be non-empty and must not include the alias/ prefix."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before a scheduled RDS KMS key deletion."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "The KMS deletion window must be between 7 and 30 days."
  }
}

variable "tags" {
  description = "Tags applied to RDS and supporting resources."
  type        = map(string)
  default     = {}
}
