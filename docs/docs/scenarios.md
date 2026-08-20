Scenario 001: Convert RDS PostgreSQL to Multi-AZ

Business request:
The customer has reviewed the application architecture and determined that the current single-instance PostgreSQL database does not meet their availability requirements. They submit a change request to enable Multi-AZ deployment for the production database to reduce downtime during infrastructure failure or maintenance events.

Current state:
- PostgreSQL
- single RDS instance
- deployed in private database subnets
- Multi-AZ disabled

Requested change:
Enable Multi-AZ deployment for the production RDS instance.

Expected engineering work:
- review availability and cost tradeoffs
- determine Terraform changes
- review subnet/AZ requirements
- assess maintenance/failover implications
- update architecture/network diagrams if required
- generate and review Terraform plan
- execute change through the normal change-management process
- validate application/database connectivity after failover capability is enabled

Learning objectives:
- understand RDS Multi-AZ architecture
- evaluate HA versus cost
- modify existing Terraform safely
- reason through production change impact
- validate a change against an existing architecture
