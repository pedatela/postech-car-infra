output "keycloak_alb_dns" {
  value       = aws_lb.keycloak.dns_name
  description = "DNS público do Keycloak"
}

output "app_alb_dns" {
  value       = aws_lb.app.dns_name
  description = "DNS público da aplicação"
}

output "db_endpoint" {
  value       = aws_db_instance.keycloak.address
  description = "Endpoint do Postgres usado pelo Keycloak"
}

output "keycloak_service_name" {
  value       = aws_ecs_service.keycloak.name
  description = "Nome do serviço ECS do Keycloak"
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
