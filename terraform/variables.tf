variable "project_name" {
  description = "Projeto/identificador base"
  type        = string
  default     = "postech-keycloak"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "keycloak_version" {
  description = "Tag da imagem oficial do Keycloak"
  type        = string
  default     = "24.0"
}

variable "admin_user" {
  description = "Usuário administrador do Keycloak"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Senha do admin (armazene em secret/var e passe via CLI)"
  type        = string
}

variable "db_admin_password" {
  description = "Senha do Postgres do Keycloak"
  type        = string
}

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Armazenamento em GB"
  type        = number
  default     = 20
}

variable "desired_count" {
  description = "Número de tasks Keycloak"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Porta exposta pelo Keycloak"
  type        = number
  default     = 8080
}

variable "keycloak_hostname" {
  description = "Hostname configurado no Keycloak (ALB DNS ou custom)"
  type        = string
  default     = ""
}

variable "app_container_image" {
  description = "Imagem (URI completo) utilizada pela aplicação principal; deixe vazio para usar o ECR criado aqui"
  type        = string
  default     = ""
}

variable "app_container_port" {
  description = "Porta exposta pela aplicação principal"
  type        = number
  default     = 3000
}

variable "app_desired_count" {
  description = "Número de tasks ECS para a aplicação principal"
  type        = number
  default     = 1
}
