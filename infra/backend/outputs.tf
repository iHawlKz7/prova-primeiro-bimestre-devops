output "bucket_name" {
  value = var.bucket_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}