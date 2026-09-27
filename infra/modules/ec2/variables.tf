variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "subnet_id" {
  description = "Subnet publica utilizada pela EC2"
  type        = string
}

variable "security_group_id" {
  description = "Security Group da EC2"
  type        = string
}

variable "db_host" {
  description = "Endpoint do RDS PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nome do banco PostgreSQL"
  type        = string
}

variable "db_username" {
  description = "Usuario do PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "repository_url" {
  description = "URL publica do repositorio GitHub"
  type        = string
}