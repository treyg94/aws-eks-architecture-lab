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

## Current VPC scope

The initial VPC module creates only:

- One VPC with a configurable IPv4 CIDR block
- Configurable DNS support and DNS hostnames, enabled by each environment
- A consistent `Name` tag plus caller-supplied common tags
- Outputs for the VPC ID and CIDR

## Deliberately unresolved decisions

The following choices require explicit design work in later tasks and are not encoded yet:

- Availability Zone count and selection
- Public, private, database, or intra-subnet layout and CIDR allocation
- Internet gateway and routing design
- NAT gateway count, placement, and Dev cost tradeoffs
- VPC endpoints and egress controls
- EKS topology, node capacity, and cluster access
- Remote Terraform state backend and state isolation details
- Departmental service control policy contents
