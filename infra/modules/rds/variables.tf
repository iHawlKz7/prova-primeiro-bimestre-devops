variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas onde o RDS sera criado"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security Group permitido no RDS"
  type        = string
}

variable "db_name" {
  description = "Nome do banco PostgreSQL"
  type        = string
}

variable "db_username" {
  description = "Usuario administrador do PostgreSQL"
  type        = string
}

variable "db_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
}