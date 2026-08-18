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

Test and Prod each include one internet-facing Application Load Balancer spanning all environment public subnets. Each ALB forwards HTTP to an IP target group on the environment-configured application port. HTTPS configuration is supported but remains disabled until an ACM certificate ARN is supplied; when enabled, HTTP changes to a permanent HTTPS redirect. Dev does not create an ALB.

Planned application DNS names are documentation-only and are not created by Terraform yet:

- `dev.tsconsultingllc.com`
- `test.tsconsultingllc.com`
- `prod.tsconsultingllc.com`

## Target architecture

The AWS Organizations management account is `treyslab`. A separate workload account normally resides in the `App1` organizational unit and contains all three application environments. The workload account may temporarily move among the `Finance`, `HR`, `Legal`, and `IT` OUs for future service control policy exercises.

Future iterations may add data services, Kubernetes ingress integration, DNS records, certificates, monitoring, and autoscaling. These components are outside the current implementation.

## Repository structure

```text
terraform/
|-- modules/
|   |-- vpc/
|   |-- alb/
|   `-- eks/
|       |-- cluster/
|       |-- managed-nodes/
|       `-- fargate/
`-- environments/
    |-- dev/
    |-- test/
    `-- prod/
```

Each directory under `terraform/environments` is an independent Terraform root module. Its committed `terraform.tfvars` contains non-sensitive environment architecture inputs. Run Terraform commands from the environment you intend to inspect or deploy.

## Safety

Do not commit credentials, account-specific secrets, Terraform state, sensitive variable files, or private keys. Terraform provider lock files are intentionally committed for reproducible provider selection.

No AWS resources should be created from this repository without first reviewing the plan, expected costs, and the active AWS account and identity.

See [docs/decisions.md](docs/decisions.md) for the architectural decisions and deliberately unresolved items.
