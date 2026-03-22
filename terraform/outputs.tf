output "app_alb_dns" {
  value       = aws_lb.app.dns_name
  description = "DNS público da aplicação"
}

output "app_service_name" {
  value       = aws_ecs_service.app.name
  description = "Nome do serviço ECS da aplicação"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "Cluster ECS compartilhado"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL do repositório ECR da aplicação"
}

output "cognito_user_pool_id" {
  value       = aws_cognito_user_pool.this.id
  description = "ID do User Pool Cognito"
}

output "cognito_user_pool_client_id" {
  value       = aws_cognito_user_pool_client.this.id
  description = "ID do App Client do Cognito"
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.this.domain
  description = "Subdomínio público do Cognito Hosted UI"
}
