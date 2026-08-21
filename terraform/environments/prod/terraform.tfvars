cluster_name                        = "app1-prod-eks"
kubernetes_version                  = "1.36"
cluster_subnet_type                 = "private_app"
cluster_public_access_cidrs         = ["104.189.79.218/32"]
enable_managed_nodes                = false
enable_fargate                      = true
workload_identity_mode              = "irsa"
workload_security_group_name_prefix = "app1-prod"

workload_identity = {
  namespace = "app"
  identities = {
    frontend = {
      service_account_name = "frontend"
      role_name            = "app1-prod-frontend"
    }
    backend = {
      service_account_name = "backend"
      role_name            = "app1-prod-backend"
    }
  }
}

fargate_profiles = [
  {
    name = "app-fargate"
    selectors = [
      {
        namespace = "app"
        labels = {
          infrastructure = "fargate"
        }
      }
    ]
  },
  {
    name = "coredns-fargate"
    selectors = [
      {
        namespace = "kube-system"
        labels = {
          k8s-app = "kube-dns"
        }
      }
    ]
  }
]

alb = {
  name              = "app1-prod-alb"
  target_port       = 80
  health_check_path = "/"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

dns = {
  hosted_zone_name   = "tsconsultingllc.com"
  record_name        = "prod.tsconsultingllc.com"
  certificate_domain = "*.tsconsultingllc.com"
}

rds = {
  identifier              = "app1-prod-postgres"
  engine_version          = "17"
  instance_class          = "db.t4g.micro"
  storage_type            = "gp3"
  allocated_storage       = 30
  master_username         = "app1admin"
  publicly_accessible     = false
  operator_access_cidrs   = []
  backup_retention_period = 1
  kms_alias_name          = "app1-prod-rds"
}

frontend_api_url_parameter = {
  name  = "/app1/prod/frontend/api-url"
  value = "https://api.prod.example.invalid"
}
