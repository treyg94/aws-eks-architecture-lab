# AWS EKS Architecture Lab

This repository is an incremental, production-shaped AWS architecture lab built with Terraform. It is intended to develop practical AWS, Amazon EKS, infrastructure-as-code, governance, and troubleshooting skills while keeping architectural decisions visible and understandable.

## Current state

The current implementation provides a reusable VPC network module and separate Terraform root modules for the App1 Dev, Test, and Prod environments. The module creates VPCs, subnets, an Internet Gateway, route tables, and optional single-NAT egress for private application subnets.

| Environment | VPC CIDR | Topology |
| --- | --- | --- |
| Dev | `10.10.0.0/16` | Two AZs; public and private application subnets; no NAT gateway |
| Test | `10.20.0.0/16` | Three AZs; public, private application, and isolated private database subnets; one NAT gateway |
| Prod | `10.30.0.0/16` | Same three-AZ topology as Test; one NAT gateway |

Public subnets are normally reserved for edge resources. Test and Prod workloads remain private, and private database subnets have no direct internet route. Dev managed nodes are a deliberate lab exception and run in its public subnets. The single-NAT design in Test and Prod is a documented cost-versus-resiliency tradeoff.

The EKS foundation uses Kubernetes `1.36`, enables public and private API endpoints, restricts the public endpoint to the documented operator CIDR, retains all control-plane logs for three days, and manages the VPC CNI, CoreDNS, and kube-proxy add-ons. The active Terraform caller's durable IAM principal receives cluster-admin access through an EKS Access Entry.

| Environment | EKS compute |
| --- | --- |
| Dev | One `t3.small` managed node by default, scaling to two, in public subnets |
| Test | Two `t3.small` managed nodes by default, scaling between one and two, in private application subnets |
| Prod | Fargate-only: an application profile and a dedicated CoreDNS profile in private application subnets |

Test and Prod each include one internet-facing Application Load Balancer spanning all environment public subnets. Each ALB exposes HTTPS using the shared wildcard ACM certificate, redirects HTTP to HTTPS, and forwards to an IP target group on port 80 with health checks at `/`. Dev does not create an ALB.

The grouped `shared/dns-acm` Terraform root looks up the existing public `tsconsultingllc.com` hosted zone and owns one DNS-validated `*.tsconsultingllc.com` ACM certificate. Test and Prod discover that issued certificate and create Route 53 aliases for:

- `test.tsconsultingllc.com`
- `prod.tsconsultingllc.com`

`dev.tsconsultingllc.com` remains reserved in documentation only.

The `terraform/bootstrap/state-backend` root defines the future remote-state foundation: a versioned, private S3 bucket encrypted by a customer-managed KMS key. It is intentionally separate from environment and shared-service roots because those roots will depend on the backend it creates. The bootstrap root continues to use local state and must be preserved securely.

## Target architecture

The AWS Organizations management account is `treyslab`. A separate workload account normally resides in the `App1` organizational unit and contains all three application environments. The workload account may temporarily move among the `Finance`, `HR`, `Legal`, and `IT` OUs for future service control policy exercises.

Future iterations may add data services, Kubernetes ingress integration, monitoring, and autoscaling. These components are outside the current implementation.

## Repository structure

```text
terraform/
|-- bootstrap/
|   `-- state-backend/
|-- modules/
|   |-- vpc/
|   |-- alb/
|   |-- dns-acm/
|   |-- dns-alias/
|   `-- eks/
|       |-- cluster/
|       |-- managed-nodes/
|       `-- fargate/
`-- environments/
    |-- dev/
    |-- test/
    |-- prod/
    `-- shared/
        `-- dns-acm/
```

Each leaf directory under `terraform/environments` is an independent Terraform root module. Shared infrastructure is grouped by service under `terraform/environments/shared`, such as `shared/dns-acm` and a future `shared/cloudwatch`. Each root's committed `terraform.tfvars` contains non-sensitive architecture inputs.

Apply the `shared/dns-acm` root before Test or Prod so their certificate data lookup can find the issued wildcard certificate. Run Terraform commands only from the root you intend to inspect or deploy.

## Future remote state

This feature creates only the backend infrastructure definition; existing Terraform roots have not been migrated. After the bootstrap root is applied and its local state is secured, future backend configurations will use the bootstrap outputs with these keys:

| Terraform root | S3 backend key |
| --- | --- |
| Shared DNS/ACM | `shared/dns-acm/terraform.tfstate` |
| Dev | `dev/terraform.tfstate` |
| Test | `test/terraform.tfstate` |
| Prod | `prod/terraform.tfstate` |

Each migrated root will use an S3 backend configuration shaped like:

```hcl
terraform {
  backend "s3" {
    bucket       = "<state_bucket_name>"
    key          = "<root-specific-key>"
    region       = "us-east-1"
    encrypt      = true
    kms_key_id   = "<kms_key_arn>"
    use_lockfile = true
  }
}
```

S3 native lock files will provide state locking; no DynamoDB locking table is planned. The backend bucket enables versioning, blocks all public access, enforces TLS through a deny policy, and uses default SSE-KMS encryption with the dedicated customer-managed key.

## Safety

Do not commit credentials, account-specific secrets, Terraform state, sensitive variable files, private keys, or the bootstrap root's local state. Terraform provider lock files are intentionally committed for reproducible provider selection.

No AWS resources should be created from this repository without first reviewing the plan, expected costs, and the active AWS account and identity.

See [docs/decisions.md](docs/decisions.md) for the architectural decisions and deliberately unresolved items.
