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

## EKS workload identity foundation

- EKS Pod Identity is the preferred workload identity model because it avoids per-cluster IAM OIDC trust configuration and provides direct EKS associations between service accounts and IAM roles.
- Dev and Test use EKS Pod Identity because their workloads run on supported Linux EC2 worker nodes. Both clusters install the EKS Pod Identity Agent add-on.
- Prod remains intentionally Fargate-only. AWS does not support EKS Pod Identity for Fargate workloads, so Prod uses IAM roles for service accounts (IRSA) and a cluster-specific IAM OIDC provider.
- The mixed design is intentional and provides a lab comparison between EKS Pod Identity and IRSA while preserving the selected compute architecture.
- Every environment defines separate `frontend` and `backend` workload identities for the `app` namespace. Each service account receives its own environment-isolated IAM role to support later least-privilege testing.
- Workload roles intentionally begin without attached application permission policies. Exact least-privilege access to services such as Secrets Manager, S3, databases, or queues will be added only when those services are introduced.
- Terraform creates only the AWS identity integrations and may reference the intended namespace and service-account names before Kubernetes creates those objects during the workload configuration phase.

## Future scenarios

1. Test EKS access and Kubernetes RBAC with cluster administrators, namespace-scoped developers, and read-only identities.
2. Cut over one environment from default EKS encryption to a customer-managed KMS key and document the operational behavior.
3. Temporarily scale Dev from one to two nodes to test scheduling and node or Availability Zone failure behavior.

## Application Load Balancer foundation

- Test and Prod each have one internet-facing Application Load Balancer spanning every public subnet in the environment. Dev does not create an ALB.
- The reusable ALB module creates an IP target group. The initial environment input uses HTTP port 80 and the root health-check path; both remain configurable.
- The ALB security group accepts public TCP 80 and 443. Egress is limited to the configured application target port within the environment VPC CIDR.
- Test and Prod use HTTPS listeners with the shared wildcard ACM certificate and permanently redirect HTTP to HTTPS.
- AWS Load Balancer Controller, target registration, and Kubernetes resources remain intentionally deferred.

## Shared DNS and ACM foundation

- Shared infrastructure is organized as service-specific Terraform roots under `terraform/environments/shared`. The first root is `shared/dns-acm`; future shared services should use peers such as `shared/cloudwatch`, rather than a flat shared root.
- `shared/dns-acm` looks up the existing public `tsconsultingllc.com` Route 53 hosted zone. Terraform does not create or own the hosted zone.
- The shared root owns one Amazon-issued `*.tsconsultingllc.com` ACM certificate, its Route 53 DNS validation records, and certificate validation.
- Test and Prod do not own certificates. Each environment looks up the issued wildcard certificate by domain and status before configuring its ALB HTTPS listener.
- Test owns the `test.tsconsultingllc.com` Route 53 alias to its ALB. Prod owns the `prod.tsconsultingllc.com` alias to its ALB.
- `dev.tsconsultingllc.com` remains reserved in documentation only; no Dev ALB or DNS record is created.
- The shared DNS/ACM root must be applied before Test or Prod because their certificate lookups require an issued certificate.

## Terraform state backend foundation

- Backend infrastructure lives in `terraform/bootstrap/state-backend`, separate from `terraform/environments/shared`. Bootstrap infrastructure must exist before environment and shared-service roots can use it, so treating it as an ordinary shared service would create a dependency cycle.
- The bootstrap root intentionally keeps local Terraform state and does not configure itself to use the S3 bucket it creates. Its local state must be stored securely and backed up by the operator.
- The bootstrap root creates one S3 state bucket and one customer-managed KMS key with a friendly alias. The bucket name combines a configurable project prefix with the current AWS account ID and region without committing an account identifier.
- Bucket versioning is enabled, all four S3 Block Public Access controls are enabled, default encryption uses the customer-managed KMS key, and the bucket policy denies requests that do not use TLS.
- The bucket and KMS key use Terraform `prevent_destroy`; the bucket does not allow force deletion. KMS rotation is enabled and its deletion window is 30 days.
- After a later explicit migration, the S3 bucket will become the authoritative state location for Dev, Test, Prod, and shared infrastructure.
- Planned state keys are `shared/dns-acm/terraform.tfstate`, `dev/terraform.tfstate`, `test/terraform.tfstate`, and `prod/terraform.tfstate`.
- Migrated roots will use S3 native state locking with `use_lockfile = true`. No DynamoDB locking table is created or planned.
- This feature does not migrate state or add backend blocks to any existing Terraform root.

## Shared ECR foundation

- ECR is shared infrastructure owned by the service-specific `terraform/environments/shared/ecr` root, not by Dev, Test, or Prod.
- One configurable repository stores the main App1 application container image for use across the lab environments.
- Image tags are immutable so an existing tag cannot silently be moved to different image content. Scan-on-push is enabled to identify image vulnerabilities when images enter the repository.
- A dedicated customer-managed KMS key with rotation enabled and a friendly alias encrypts repository content.
- Configurable lifecycle rules remove untagged images after seven days and cap total retained image history at 20 images by default. These lab-friendly defaults limit stale storage while preserving recent images for testing and rollback exercises.
- Application image builds and pushes are intentionally deferred until the EKS workload is configured. This foundation does not create workloads, Kubernetes resources, or delivery pipelines.

## RDS PostgreSQL foundation

- Dev, Test, and Prod each own an isolated standard RDS for PostgreSQL instance through their existing environment root; database infrastructure is not shared between environments.
- PostgreSQL major version 17 is pinned while AWS-supported automatic minor version upgrades remain enabled. Each environment starts with a single `db.t4g.micro` instance, 30 GiB of gp3 storage, and Multi-AZ disabled to support later capacity and availability exercises.
- Test and Prod RDS instances are not publicly accessible and use only their isolated private database subnets.
- Dev is an intentional convenience exception for direct desktop administration and testing: its RDS instance uses the existing Dev public subnets and is publicly accessible, but PostgreSQL ingress is restricted to the existing operator `104.189.79.218/32` CIDR and the dedicated backend workload security group. Internet-wide ingress is prohibited.
- Every environment receives a dedicated backend workload security group and an RDS security group. PostgreSQL TCP/5432 is allowed only from the backend group, plus the Dev-only operator CIDR. The backend group will be attached to backend compute during the later Kubernetes workload configuration phase; the frontend receives no database network path.
- RDS manages the master password in Secrets Manager using the environment-specific RDS KMS key; Terraform does not generate, store, or expose the password. IAM database authentication is enabled for future backend application access.
- The identity modules continue to own the workload IAM roles, while each environment root composes a resource-specific inline policy authorizing only its backend role to call `rds-db:connect` for its own RDS resource ID and the shared logical PostgreSQL application username `app1_backend`. Wildcard database resource IDs, wildcard usernames, frontend database permissions, and master-secret permissions are prohibited.
- Backend database access requires both network authorization from the backend workload security group to the environment RDS security group on PostgreSQL TCP/5432 and IAM authorization through the environment-scoped `rds-db:connect` policy. The actual `app1_backend` PostgreSQL user and its `rds_iam` grant are intentionally deferred to the later database/platform configuration phase.
- Each environment uses a separate rotating customer-managed KMS key and friendly alias for database storage and the RDS-managed master secret.
- Automated backups are retained for one day. Deletion protection and Multi-AZ are disabled, but deletion requires a final snapshot with a random suffix generated once per RDS resource lifecycle. The suffix remains stable across plans and applies and is regenerated after a full destroy and later recreation to prevent retained-snapshot name collisions.
- Scenario 001 in `docs/scenarios.md` records the future production Multi-AZ change request and its engineering considerations; Multi-AZ is not implemented in this foundation.

## Workload network identity and Parameter Store foundation

- Each environment instantiates the reusable `workload-security-groups` module and owns separate, application-named frontend and backend workload security groups tagged as workload networking. The RDS module owns only its database security group and the connectivity rules involving it. Only the backend group is authorized to reach its environment RDS security group on PostgreSQL TCP/5432; the frontend group has no RDS ingress or egress rule and receives no database IAM authentication or master-secret permission.
- These workload security groups are infrastructure prepared now, but they are not attached to Kubernetes workloads until the later EKS/platform configuration phase.
- Dev and Test's EC2-backed EKS clusters attach `AmazonEKSVPCResourceController` to the existing cluster IAM role and configure the VPC CNI add-on with `ENABLE_POD_ENI=true`, preparing the AWS-side prerequisites for Security Groups for Pods. The later Kubernetes/platform phase will create `SecurityGroupPolicy` resources that select frontend and backend Pods and assign their corresponding workload groups.
- For Prod's Fargate-only cluster, Kubernetes `SecurityGroupPolicy` resources will assign the corresponding frontend and backend workload groups. Fargate does not require EC2 Pod ENI enablement, and the policies must preserve required EKS cluster and control-plane communication.
- Dev, Test, and Prod each own one non-sensitive SSM Parameter Store `String` parameter for the frontend API URL: `/app1/dev/frontend/api-url`, `/app1/test/frontend/api-url`, and `/app1/prod/frontend/api-url` respectively. These parameters are environment infrastructure, not shared infrastructure.
- Each frontend workload role receives only `ssm:GetParameter` on its exact environment-specific parameter ARN. Backend roles receive no Parameter Store permission from this foundation, and wildcard Parameter Store access is prohibited.
- Planned security tests verify that each frontend can read only its own environment API URL, cross-environment reads fail, frontend cannot connect to PostgreSQL or access the RDS master secret, backend is network-authorized on TCP/5432, and backend later authenticates to PostgreSQL with IAM database authentication.
- Kubernetes `SecurityGroupPolicy` objects remain intentionally deferred and are not implemented by this foundation.

## Major architecture decision: controlled VPC CNI configuration

- The EKS cluster module's structured `vpc_cni` object is the authoritative interface for supported Amazon VPC CNI configuration. Environment roots cannot pass arbitrary raw add-on `configuration_values` or unsupported CNI keys.
- Supported Terraform fields are translated inside the module to their AWS VPC CNI environment-variable names and string values, then encoded with `jsonencode`. Null optional settings are omitted. Adding a future CNI capability requires extending the structured object, adding applicable validation, updating this translation, and opting in only the environments that need it.
- This controlled interface intentionally keeps VPC CNI concepts visible for EKS learning while providing typed inputs, validation, and reviewable environment differences.
- Dev and Test enable Pod ENI support for future Security Groups for Pods. The EKS module conditionally attaches the EKS-specific `AmazonEKSVPCResourceController` managed policy to their existing cluster roles; it does not attach that policy to node, workload, or Fargate roles.
- Prod remains Fargate-only, does not enable the EC2 Pod ENI path, and does not receive the VPC Resource Controller policy through this capability.
- `pod_security_group_enforcing_mode` supports only `standard` or `strict`, but remains unset because that architecture choice has not been made. The module therefore omits `POD_SECURITY_GROUP_ENFORCING_MODE` until a later explicit decision.
- Prefix delegation, warm-IP tuning, custom networking, and Kubernetes `SecurityGroupPolicy` resources are not enabled by this decision.

## Deferred post-deployment database configuration

The PostgreSQL application role is intentionally not created as part of the AWS Terraform buildout.

After the RDS instance is deployed and reachable, create the logical application database user inside PostgreSQL:

    CREATE USER app1_backend;
    GRANT rds_iam TO app1_backend;

Grant only the database, schema, and object privileges required by the backend application.

This is a post-deployment database configuration task. AWS Terraform is responsible for enabling RDS IAM database authentication and granting the backend workload IAM role `rds-db:connect` access to the `app1_backend` database user. The PostgreSQL user itself is configured inside the database after deployment.
