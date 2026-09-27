output "ec2_public_ip" {
  description = "IP público da EC2"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "Endpoint privado do RDS"
  value       = module.rds.endpoint
}

output "api_url" {
  description = "URL pública da API"
  value       = "http://${module.ec2.public_ip}:3000"
}