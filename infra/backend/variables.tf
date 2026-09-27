variable "bucket_name" {
  description = "Nome do bucket S3 para Remote State"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para locking"
  type        = string
}