variable "project_name" {
  description = "Projeto/identificador base"
  type        = string
  default     = "postech-app"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
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

variable "cognito_callback_urls" {
  description = "Lista de URLs de callback autorizadas no Cognito"
  type        = list(string)
  default = [
    "http://localhost:3000/callback"
  ]
}

variable "cognito_logout_urls" {
  description = "Lista de URLs de logout autorizadas no Cognito"
  type        = list(string)
  default = [
    "http://localhost:3000/logout"
  ]
}
