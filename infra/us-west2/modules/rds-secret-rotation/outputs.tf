output "rotation_lambda_arn" {
  value = aws_lambda_function.rotation_lambda.arn
}

output "rotation_enabled" {
  value = aws_secretsmanager_secret_rotation.rotation.rotation_enabled
}

output "pymysql_layer_arn" {
  value = aws_lambda_layer_version.pymysql.arn
}

output "lambda_sg_id" {
  value = var.ecs_tasks_sg_id
}


