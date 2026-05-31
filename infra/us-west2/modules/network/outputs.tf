# Outputs for Network Module
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnets" {
  value       = [for s in aws_subnet.public : s.id]
  description = "Public subnet IDs"
}

output "private_subnets" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Private subnet IDs"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private route table ID"
}

output "ecs_tasks_sg_id" {
  description = "Security group for ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}


