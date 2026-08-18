cluster_name                = "app1-test-eks"
kubernetes_version          = "1.36"
cluster_subnet_type         = "private_app"
cluster_public_access_cidrs = ["104.189.79.218/32"]
enable_managed_nodes        = true
enable_fargate              = false

managed_nodes = {
  node_group_name = "app1-test-managed"
  subnet_type     = "private_app"
  instance_types  = ["t3.small"]
  disk_size       = 30
  min_size        = 1
  desired_size    = 2
  max_size        = 2
}
