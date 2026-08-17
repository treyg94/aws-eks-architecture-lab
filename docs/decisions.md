# Architecture Decisions

This document records decisions already made for the lab and distinguishes them from choices that remain open.

## Account and organization model

- The lab uses two AWS accounts: an AWS Organizations management account and a separate member/workload account.
- The existing `treyslab` account is the management account. AWS Organizations, service control policy management, governance, and centralized or platform functions belong there.
- The organization has `App1`, `Finance`, `HR`, `Legal`, and `IT` organizational units beneath the root.
- The workload account normally resides in the `App1` OU.
- For governance exercises, the workload account may be moved temporarily into the departmental OUs to test and observe different service control policies. Departmental SCPs are not part of the current implementation.

## Application environments

The workload account hosts one application, App1, with three isolated environment VPCs:

| Environment | CIDR | Design intent |
| --- | --- | --- |
| Dev | `10.10.0.0/16` | Lower cost and greater flexibility; any reduction in redundancy or controls must be deliberate and documented, while retaining basic security hygiene |
| Test | `10.20.0.0/16` | Mirrors Prod as closely as practical so changes can be validated before production |
| Prod | `10.30.0.0/16` | Production-shaped security, resiliency, and multi-AZ design where appropriate |

## Terraform structure

- Reusable infrastructure belongs in modules rather than being duplicated between environments.
- Dev, Test, and Prod are separate Terraform root modules and can therefore have independent configuration and state.
- All three environments consume the same VPC module for their minimum VPC foundation.
- Resource names and tags identify the application and environment.
- Terraform provider dependency lock files are committed. Terraform working directories, state, local plans, CLI configuration, and variable files are excluded from Git.

## Network foundation

- All environments are IPv4-only and use explicit subnet CIDRs and Availability Zones in their environment root modules.
- Public subnets have an Internet Gateway route and are reserved for edge resources. Application workloads remain in private application subnets.
- Dev spans `us-east-1a` and `us-east-1b`. It has two public and two private application subnets and no NAT gateway. Its private workloads have no default internet route.
- Test and Prod use the same topology across `us-east-1a`, `us-east-1b`, and `us-east-1c`: three public, three private application, and three isolated private database subnets.
- Test and Prod each use one NAT gateway, placed in the first public subnet (`us-east-1a`), for private application subnet egress. This is a deliberate cost tradeoff and creates an Availability Zone dependency for outbound traffic.
- Private database route tables have no direct internet or NAT route.
- Each subnet group shares one route table within an environment. The module manages explicit route table associations.

| Environment | Public CIDRs | Private application CIDRs | Private database CIDRs |
| --- | --- | --- | --- |
| Dev | `10.10.0.0/24`, `10.10.1.0/24` | `10.10.10.0/24`, `10.10.11.0/24` | None |
| Test | `10.20.0.0/24`, `10.20.1.0/24`, `10.20.2.0/24` | `10.20.10.0/24`, `10.20.11.0/24`, `10.20.12.0/24` | `10.20.20.0/24`, `10.20.21.0/24`, `10.20.22.0/24` |
| Prod | `10.30.0.0/24`, `10.30.1.0/24`, `10.30.2.0/24` | `10.30.10.0/24`, `10.30.11.0/24`, `10.30.12.0/24` | `10.30.20.0/24`, `10.30.21.0/24`, `10.30.22.0/24` |

## Deliberately unresolved decisions

The following choices require explicit design work in later tasks and are not encoded yet:

- VPC endpoints and egress controls
- EKS topology, node capacity, and cluster access
- Remote Terraform state backend and state isolation details
- Departmental service control policy contents
