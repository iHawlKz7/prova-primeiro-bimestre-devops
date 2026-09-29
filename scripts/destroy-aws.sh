#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY_URL="https://github.com/iHawlKz7/prova-primeiro-bimestre-devops.git"

echo "========================================"
echo " TechNova - Destroy AWS"
echo "========================================"

echo
echo "[1/6] Validando credenciais AWS..."

aws sts get-caller-identity >/dev/null

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET_NAME="technova-devops-state-${ACCOUNT_ID}-6325192"
LOCK_TABLE="technova-devops-locks-6325192"

echo "AWS Account: ${ACCOUNT_ID}"
echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB: ${LOCK_TABLE}"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo
  echo "DB_PASSWORD nao esta definida nesta sessao."
  read -rsp "Digite uma senha valida apenas para o Terraform destroy: " DB_PASSWORD
  echo
  export DB_PASSWORD
fi

if (( ${#DB_PASSWORD} < 8 || ${#DB_PASSWORD} > 128 )); then
  echo "ERRO: DB_PASSWORD deve possuir entre 8 e 128 caracteres."
  exit 1
fi

echo
echo "[2/6] Identificando IP publico..."

PUBLIC_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '\n')"

if [[ -z "${PUBLIC_IP}" ]]; then
  echo "ERRO: nao foi possivel identificar o IP publico."
  exit 1
fi

SSH_CIDR="${PUBLIC_IP}/32"

echo "SSH CIDR usado pelo destroy: ${SSH_CIDR}"

echo
echo "[3/6] Destruindo infraestrutura principal..."

cd "${ROOT_DIR}/infra"

terraform init \
  -reconfigure \
  -input=false \
  -backend-config="bucket=${BUCKET_NAME}" \
  -backend-config="key=prova/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=${LOCK_TABLE}" \
  -backend-config="encrypt=true"

terraform destroy \
  -auto-approve \
  -input=false \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=${REPOSITORY_URL}"

echo
echo "===== TERRAFORM STATE APOS DESTROY PRINCIPAL ====="

STATE_AFTER_DESTROY="$(terraform state list)"

if [[ -n "${STATE_AFTER_DESTROY}" ]]; then
  echo "${STATE_AFTER_DESTROY}"
  echo "ERRO: ainda existem recursos no state principal."
  exit 1
fi

echo "State principal vazio."

echo
echo "[4/6] Removendo DynamoDB de locking..."

cd "${ROOT_DIR}/infra/backend"

terraform init -input=false

terraform destroy \
  -auto-approve \
  -input=false \
  -var="bucket_name=${BUCKET_NAME}" \
  -var="dynamodb_table_name=${LOCK_TABLE}"

echo
echo "[5/6] Removendo todas as versoes do bucket S3..."

if aws s3api head-bucket \
  --bucket "${BUCKET_NAME}" \
  >/dev/null 2>&1
then
  while true; do
    DELETE_JSON="$(
      aws s3api list-object-versions \
        --bucket "${BUCKET_NAME}" \
        --output json |
      python3 -c '
import json
import sys

data = json.load(sys.stdin)
objects = []

for group in ("Versions", "DeleteMarkers"):
    for item in data.get(group) or []:
        key = item.get("Key")
        version_id = item.get("VersionId")

        if key and version_id:
            objects.append({
                "Key": key,
                "VersionId": version_id
            })

print(json.dumps({
    "Objects": objects,
    "Quiet": True
}))
'
    )"

    OBJECT_COUNT="$(
      printf '%s' "${DELETE_JSON}" |
      python3 -c '
import json
import sys

data = json.load(sys.stdin)
print(len(data.get("Objects", [])))
'
    )"

    if [[ "${OBJECT_COUNT}" -eq 0 ]]; then
      break
    fi

    echo "Removendo ${OBJECT_COUNT} versao(oes)/marcador(es)..."

    aws s3api delete-objects \
      --bucket "${BUCKET_NAME}" \
      --delete "${DELETE_JSON}" \
      >/dev/null
  done

  aws s3api delete-bucket \
    --bucket "${BUCKET_NAME}" \
    --region us-east-1

  echo "Bucket removido."
else
  echo "Bucket ja nao existe."
fi

echo
echo "[6/6] Verificacao final..."

FAIL=0

echo
echo "===== EC2 ====="

EC2_ACTIVE="$(
  aws ec2 describe-instances \
    --filters \
      "Name=tag:Name,Values=technova-reservas-api" \
      "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query 'length(Reservations[].Instances[])' \
    --output text
)"

echo "Instancias ativas encontradas: ${EC2_ACTIVE}"

if [[ "${EC2_ACTIVE}" != "0" ]]; then
  echo "ERRO: EC2 ainda ativa."
  FAIL=1
else
  echo "EC2 removida/terminada."
fi

echo
echo "===== RDS ====="

if aws rds describe-db-instances \
  --db-instance-identifier technova-reservas-postgres \
  >/dev/null 2>&1
then
  echo "ERRO: RDS ainda existe."
  FAIL=1
else
  echo "RDS removido."
fi

echo
echo "===== VPC ====="

VPC_COUNT="$(
  aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=technova-reservas-vpc" \
    --query 'length(Vpcs)' \
    --output text
)"

echo "VPCs encontradas: ${VPC_COUNT}"

if [[ "${VPC_COUNT}" != "0" ]]; then
  echo "ERRO: VPC ainda existe."
  FAIL=1
else
  echo "VPC removida."
fi

echo
echo "===== DYNAMODB ====="

if aws dynamodb describe-table \
  --table-name "${LOCK_TABLE}" \
  >/dev/null 2>&1
then
  echo "ERRO: DynamoDB ainda existe."
  FAIL=1
else
  echo "DynamoDB removido."
fi

echo
echo "===== S3 ====="

if aws s3api head-bucket \
  --bucket "${BUCKET_NAME}" \
  >/dev/null 2>&1
then
  echo "ERRO: bucket S3 ainda existe."
  FAIL=1
else
  echo "Bucket S3 removido."
fi

echo

if [[ "${FAIL}" -ne 0 ]]; then
  echo "========================================"
  echo " Destroy terminou com recursos pendentes"
  echo "========================================"
  exit 1
fi

echo "========================================"
echo " Destroy completo: todos os recursos removidos"
echo "========================================"
