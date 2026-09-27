variable "project_name" {
  type    = string
  default = "technova-reservas"
}

variable "db_name" {
  type    = string
  default = "reservas"
}

variable "db_username" {
  type    = string
  default = "postgres"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR permitido para SSH"
}

variable "repository_url" {
  type = string
}