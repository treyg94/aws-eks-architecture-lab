# Lab Scenarios

## Scenario 001: Convert RDS PostgreSQL to Multi-AZ

### Business request

The customer has reviewed the application architecture and determined that the current single-instance PostgreSQL database does not meet their availability requirements. They submit a change-management request to enable Multi-AZ deployment for the production database to reduce downtime during infrastructure failure or maintenance events.

### Current state

- PostgreSQL
- Single RDS instance
- Private database subnets
- Multi-AZ disabled

### Requested change

- Enable Multi-AZ deployment for the production RDS instance.

### Expected engineering work

- Review availability and cost tradeoffs.
- Determine Terraform changes.
- Review subnet and Availability Zone requirements.
- Assess maintenance and failover implications.
- Update architecture and network documentation if required.
- Generate and review a Terraform plan.
- Execute through the normal change-management process.
- Validate application and database connectivity and failover behavior.

### Learning objectives

- Understand RDS Multi-AZ architecture.
- Evaluate high availability versus cost.
- Modify existing Terraform safely.
- Reason through production change impact.
- Validate the change against the existing architecture.
