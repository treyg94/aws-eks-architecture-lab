# AWS EKS Architecture Lab

This repository is an incremental, production-shaped AWS architecture lab built with Terraform. It is intended to develop practical AWS, Amazon EKS, infrastructure-as-code, governance, and troubleshooting skills while keeping architectural decisions visible and understandable.

## Current state

The current implementation provides a reusable VPC network module and separate Terraform root modules for the App1 Dev, Test, and Prod environments. The module creates VPCs, subnets, an Internet Gateway, route tables, and optional single-NAT egress for private application subnets.

| Environment | VPC CIDR | Topology |
| --- | --- | --- |
| Dev | `10.10.0.0/16` | Two AZs; public and private application subnets; no NAT gateway |
| Test | `10.20.0.0/16` | Three AZs; public, private application, and isolated private database subnets; one NAT gateway |
| Prod | `10.30.0.0/16` | Same three-AZ topology as Test; one NAT gateway |

Public subnets are reserved for edge resources. Workloads remain private, and private database subnets have no direct internet route. The single-NAT design in Test and Prod is a documented cost-versus-resiliency tradeoff.

## Target architecture

The AWS Organizations management account is `treyslab`. A separate workload account normally resides in the `App1` organizational unit and contains all three application environments. The workload account may temporarily move among the `Finance`, `HR`, `Legal`, and `IT` OUs for future service control policy exercises.

Future iterations may add subnets, EKS, data services, ingress, monitoring, and autoscaling. These components are outside the current implementation.

## Repository structure

```text
terraform/
|-- modules/
|   `-- vpc/
`-- environments/
    |-- dev/
    |-- test/
    `-- prod/
```

Each directory under `terraform/environments` is an independent Terraform root module. Run Terraform commands from the environment you intend to inspect or deploy.

## Safety

Do not commit credentials, account-specific secrets, Terraform state, sensitive variable files, or private keys. Terraform provider lock files are intentionally committed for reproducible provider selection.

No AWS resources should be created from this repository without first reviewing the plan, expected costs, and the active AWS account and identity.

See [docs/decisions.md](docs/decisions.md) for the architectural decisions and deliberately unresolved items.
