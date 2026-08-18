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
- Public subnets have an Internet Gateway route and are normally reserved for edge resources. Test and Prod application workloads remain in private application subnets; Dev managed nodes are a deliberate lab exception recorded in the EKS foundation decision.
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

## EKS foundation

- EKS configuration is split into reusable cluster, managed-node, and Fargate modules. Environment-specific compute choices are committed as non-sensitive Terraform input values.
- Managed nodes and Fargate have independent boolean controls so either or both compute models can be enabled later.
- Clusters use Kubernetes `1.36`, the latest Amazon EKS standard-support version when this decision was recorded.
- Both public and private Kubernetes API endpoints are enabled. Public access is limited to `104.189.79.218/32`; private access supports nodes and Fargate Pods inside the VPC.
- EKS uses its default encryption behavior. A customer-managed KMS key is intentionally deferred.
- API, audit, authenticator, controller manager, and scheduler control-plane logs are enabled with three-day CloudWatch retention for lab cost control.
- Terraform manages the VPC CNI, CoreDNS, and kube-proxy EKS add-ons.
- The cluster, managed nodes, and Fargate Pods each have dedicated IAM roles.
- The durable IAM principal behind the active Terraform session is derived from AWS identity context and receives cluster-admin access through an EKS Access Entry.
- Dev uses a `t3.small` managed node group in public subnets with 30 GiB disks and `1/1/2` minimum, desired, and maximum capacity. Fargate is disabled.
- Test uses a `t3.small` managed node group in private application subnets with 30 GiB disks and `1/2/2` capacity. Fargate is disabled.
- Prod is Fargate-only. `app-fargate` selects namespace `app` with `infrastructure=fargate`. `coredns-fargate` selects CoreDNS Pods in `kube-system` with `k8s-app=kube-dns`, and the CoreDNS add-on uses Fargate compute.

## Future scenarios

1. Test EKS access and Kubernetes RBAC with cluster administrators, namespace-scoped developers, and read-only identities.
2. Cut over one environment from default EKS encryption to a customer-managed KMS key and document the operational behavior.
3. Temporarily scale Dev from one to two nodes to test scheduling and node or Availability Zone failure behavior.

## Application Load Balancer foundation

- Test and Prod each have one internet-facing Application Load Balancer spanning every public subnet in the environment. Dev does not create an ALB.
- The reusable ALB module creates an IP target group. The initial environment input uses HTTP port 80 and the root health-check path; both remain configurable.
- The ALB security group accepts public TCP 80 and 443. Egress is limited to the configured application target port within the environment VPC CIDR.
- Until an ACM certificate ARN is supplied, the HTTP listener forwards to the target group. Supplying a certificate ARN creates the HTTPS listener and changes HTTP behavior to a permanent HTTPS redirect.
- ACM certificates, Route 53 records, AWS Load Balancer Controller, target registration, and Kubernetes resources are intentionally deferred.
- Planned DNS names are `dev.tsconsultingllc.com`, `test.tsconsultingllc.com`, and `prod.tsconsultingllc.com`. These names are documentation-only; the Dev name does not imply a current Dev ALB.
