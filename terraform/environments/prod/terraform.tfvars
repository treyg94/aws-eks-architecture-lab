cluster_name                = "app1-prod-eks"
kubernetes_version          = "1.36"
cluster_subnet_type         = "private_app"
cluster_public_access_cidrs = ["104.189.79.218/32"]
enable_managed_nodes        = false
enable_fargate              = true

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
