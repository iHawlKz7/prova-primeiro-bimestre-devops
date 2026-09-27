#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================"
echo " TechNova - Deploy AWS"
echo "========================================"

echo
echo "[1/7] Validando credenciais AWS..."

aws sts get-caller-identity >/dev/null

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET_NAME="technova-devops-state-${ACCOUNT_ID}-6325192"
LOCK_TABLE="technova-devops-locks-6325192"

echo "AWS Account: ${ACCOUNT_ID}"
echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB: ${LOCK_TABLE}"

echo
echo "[2/7] Identificando IP público..."

PUBLIC_IP=$(curl -s https://checkip.amazonaws.com | tr -d '\n')

if [[ -z "${PUBLIC_IP}" ]]; then
  echo "Não foi possível identificar o IP público."
  exit 1
fi

SSH_CIDR="${PUBLIC_IP}/32"

echo "SSH permitido somente para: ${SSH_CIDR}"

echo
echo "[3/7] Criando backend remoto..."

cd "${ROOT_DIR}/infra/backend"

terraform init -input=false

terraform apply \
  -auto-approve \
  -input=false \
  -var="bucket_name=${BUCKET_NAME}" \
  -var="dynamodb_table_name=${LOCK_TABLE}"

echo
echo "[4/7] Inicializando infraestrutura principal..."

cd "${ROOT_DIR}/infra"

terraform init \
  -reconfigure \
  -input=false \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=prova/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="encrypt=true"

echo
echo "[5/7] Validando Terraform..."

terraform fmt -recursive
terraform validate

echo
echo "[6/7] Gerando plano..."

terraform plan \
  -input=false \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=https://github.com/iHawlKz7/prova-primeiro-bimestre-devops.git" \
  -no-color \
  | tee "${ROOT_DIR}/evidencias/terraform-plan.txt"

echo
echo "[7/7] Aplicando infraestrutura..."

terraform apply \
  -auto-approve \
  -input=false \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=https://github.com/iHawlKz7/prova-primeiro-bimestre-devops.git"

echo
echo "========================================"
echo " Deploy concluído"
echo "========================================"

terraform output