# AWS EKS Architecture Lab

This repository is an incremental, production-shaped AWS architecture lab built with Terraform. It is intended to develop practical AWS, Amazon EKS, infrastructure-as-code, governance, and troubleshooting skills while keeping architectural decisions visible and understandable.

## Current state

The current implementation provides a reusable VPC module and separate Terraform root modules for the App1 Dev, Test, and Prod environments. Each environment currently creates only a VPC with DNS support, DNS hostnames, consistent naming, and common tags.

| Environment | VPC CIDR | Intent |
| --- | --- | --- |
| Dev | `10.10.0.0/16` | Lower-cost, flexible lab environment with deliberate reductions in redundancy and controls where appropriate |
| Test | `10.20.0.0/16` | Mirrors Prod as closely as practical for validation |
| Prod | `10.30.0.0/16` | Production-shaped security and resiliency |

Subnet, Availability Zone, routing, and NAT gateway design remain intentionally undecided and are not implemented yet.

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
