cluster_name                        = "app1-dev-eks"
kubernetes_version                  = "1.36"
cluster_subnet_type                 = "private_app"
cluster_public_access_cidrs         = ["104.189.79.218/32"]
enable_managed_nodes                = true
enable_fargate                      = false
workload_identity_mode              = "pod_identity"
workload_security_group_name_prefix = "app1-dev"

workload_identity = {
  namespace = "app"
  identities = {
    frontend = {
      service_account_name = "frontend"
      role_name            = "app1-dev-frontend"
    }
    backend = {
      service_account_name = "backend"
      role_name            = "app1-dev-backend"
    }
  }
}

managed_nodes = {
  node_group_name = "app1-dev-managed"
  subnet_type     = "public"
  instance_types  = ["t3.small"]
  disk_size       = 30
  min_size        = 1
  desired_size    = 1
  max_size        = 2
}

rds = {
  identifier              = "app1-dev-postgres"
  engine_version          = "17"
  instance_class          = "db.t4g.micro"
  storage_type            = "gp3"
  allocated_storage       = 30
  master_username         = "app1admin"
  publicly_accessible     = true
  operator_access_cidrs   = ["104.189.79.218/32"]
  backup_retention_period = 1
  kms_alias_name          = "app1-dev-rds"
}

frontend_api_url_parameter = {
  name  = "/app1/dev/frontend/api-url"
  value = "https://api.dev.example.invalid"
}
