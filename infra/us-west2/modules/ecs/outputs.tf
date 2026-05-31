###############################################
# ECS CLUSTER OUTPUTS
###############################################
output "cluster_id" {
  description = "ID of the ECS cluster"
  value = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value = aws_ecs_cluster.this.arn
}

###############################################
# ECS SERVICE OUTPUTS
###############################################
output "payments_service_name" {
  description = "Name of the Payments API ECS service"
  value       = aws_ecs_service.payments_api.name
}

output "kyc_service_name" {
  description = "Name of the KYC API ECS service"
  value       = aws_ecs_service.kyc_api.name
}

output "payments_service_arn" {
  description = "ARN of the Payments API ECS service"
  value       = aws_ecs_service.payments_api.id
}

output "kyc_service_arn" {
  description = "ARN of the KYC API ECS service"
  value       = aws_ecs_service.kyc_api.id
}

###############################################
# TASK DEFINITION OUTPUTS
###############################################
output "payments_task_definition_arn" {
  description = "ARN of the Payments API task definition"
  value       = aws_ecs_task_definition.payments_api.arn
}

output "kyc_task_definition_arn" {
  description = "ARN of the KYC API task definition"
  value       = aws_ecs_task_definition.kyc_api.arn
}

###############################################
# OPTIONAL: LATEST REVISION NUMBERS
###############################################
output "payments_task_revision" {
  description = "Latest revision number for Payments API task"
  value       = aws_ecs_task_definition.payments_api.revision
}

output "kyc_task_revision" {
  description = "Latest revision number for KYC API task"
  value       = aws_ecs_task_definition.kyc_api.revision
}

