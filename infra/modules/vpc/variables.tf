variable "project_name" {
  description = "Nome do projeto usado nas tags e nomes dos recursos"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR principal da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets publicas"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas"
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "availability_zones" {
  description = "Zonas de disponibilidade utilizadas"
  type        = list(string)

  default = [
    "us-east-1a",
    "us-east-1b"
  ]
}