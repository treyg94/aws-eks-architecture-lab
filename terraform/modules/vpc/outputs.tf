output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, keyed by Availability Zone."
  value       = { for availability_zone, subnet in aws_subnet.public : availability_zone => subnet.id }
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets, keyed by Availability Zone."
  value       = { for availability_zone, subnet in aws_subnet.private_app : availability_zone => subnet.id }
}

output "private_db_subnet_ids" {
  description = "IDs of the isolated private database subnets, keyed by Availability Zone."
  value       = { for availability_zone, subnet in aws_subnet.private_db : availability_zone => subnet.id }
}
