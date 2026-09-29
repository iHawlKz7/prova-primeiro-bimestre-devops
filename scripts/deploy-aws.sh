#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================"
echo " TechNova - Deploy AWS"
echo "========================================"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "ERRO: a variavel DB_PASSWORD nao esta definida."
  echo "Defina antes de executar:"
  echo "export DB_PASSWORD='SUA_SENHA'"
  exit 1
fi

REPOSITORY_URL="https://github.com/iHawlKz7/prova-primeiro-bimestre-devops.git"

echo
echo "[1/8] Validando credenciais AWS..."

aws sts get-caller-identity >/dev/null

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET_NAME="technova-devops-state-${ACCOUNT_ID}-6325192"
LOCK_TABLE="technova-devops-locks-6325192"

echo "AWS Account: ${ACCOUNT_ID}"
echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB: ${LOCK_TABLE}"

echo
echo "[2/8] Identificando IP publico..."

PUBLIC_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '\n')

if [[ -z "${PUBLIC_IP}" ]]; then
  echo "ERRO: nao foi possivel identificar o IP publico."
  exit 1
fi

SSH_CIDR="${PUBLIC_IP}/32"

echo "SSH permitido somente para: ${SSH_CIDR}"

echo
echo "[3/8] Preparando backend remoto..."

if aws s3api head-bucket \
  --bucket "${BUCKET_NAME}" \
  >/dev/null 2>&1
then
  echo "Bucket S3 ja existe: ${BUCKET_NAME}"
else
  echo "Criando bucket S3: ${BUCKET_NAME}"

  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region us-east-1
fi

echo "Garantindo versionamento do bucket..."

aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

echo "Garantindo criptografia AES256..."

aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Garantindo bloqueio de acesso publico..."

aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

echo "Garantindo tags do bucket..."

aws s3api put-bucket-tagging \
  --bucket "${BUCKET_NAME}" \
  --tagging \
  'TagSet=[{Key=Name,Value=terraform-state},{Key=Project,Value=prova-devops},{Key=Student,Value=Emar-Cristian},{Key=RA,Value=6325192}]'

echo
echo "Configurando DynamoDB para locking..."

cd "${ROOT_DIR}/infra/backend"

terraform init -input=false

terraform apply \
  -auto-approve \
  -input=false \
  -var="bucket_name=${BUCKET_NAME}" \
  -var="dynamodb_table_name=${LOCK_TABLE}"

echo
echo "[4/8] Inicializando infraestrutura principal..."

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
echo "[5/8] Validando Terraform..."

terraform fmt -recursive
terraform validate

echo
echo "[6/8] Gerando plano..."

terraform plan \
  -input=false \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=${REPOSITORY_URL}" \
  -no-color \
  | tee "${ROOT_DIR}/evidencias/terraform-plan.txt"

echo
echo "[7/8] Aplicando infraestrutura..."

terraform apply \
  -auto-approve \
  -input=false \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=${REPOSITORY_URL}"

API_URL=$(terraform output -raw api_url)

echo
echo "[8/8] Aguardando API ficar saudavel..."
echo "Endpoint: ${API_URL}/health"

MAX_ATTEMPTS=60
SLEEP_SECONDS=10

for ((attempt=1; attempt<=MAX_ATTEMPTS; attempt++)); do
  echo "Tentativa ${attempt}/${MAX_ATTEMPTS}..."

  if RESPONSE=$(curl \
    --fail \
    --silent \
    --show-error \
    --max-time 5 \
    "${API_URL}/health" 2>/dev/null)
  then
    echo
    echo "API saudavel:"
    echo "${RESPONSE}"
    echo
    echo "========================================"
    echo " Deploy concluido com sucesso"
    echo "========================================"
    echo
    terraform output
    exit 0
  fi

  sleep "${SLEEP_SECONDS}"
done

echo
echo "ERRO: a API nao ficou saudavel dentro do tempo limite."
echo "Verifique a EC2, os containers e os logs da aplicacao."
exit 1
