variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR autorizado a acessar a EC2 por SSH"
  type        = string
}