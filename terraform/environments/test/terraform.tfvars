cluster_name                = "app1-test-eks"
kubernetes_version          = "1.36"
cluster_subnet_type         = "private_app"
cluster_public_access_cidrs = ["104.189.79.218/32"]
enable_managed_nodes        = true
enable_fargate              = false
workload_identity_mode      = "pod_identity"

workload_identity = {
  namespace = "app"
  identities = {
    frontend = {
      service_account_name = "frontend"
      role_name            = "app1-test-frontend"
    }
    backend = {
      service_account_name = "backend"
      role_name            = "app1-test-backend"
    }
  }
}

managed_nodes = {
  node_group_name = "app1-test-managed"
  subnet_type     = "private_app"
  instance_types  = ["t3.small"]
  disk_size       = 30
  min_size        = 1
  desired_size    = 2
  max_size        = 2
}

alb = {
  name              = "app1-test-alb"
  target_port       = 80
  health_check_path = "/"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

dns = {
  hosted_zone_name   = "tsconsultingllc.com"
  record_name        = "test.tsconsultingllc.com"
  certificate_domain = "*.tsconsultingllc.com"
}
