output "public_ip" {
  value = aws_instance.api.public_ip
}

output "instance_id" {
  value = aws_instance.api.id
}