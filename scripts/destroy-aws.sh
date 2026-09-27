#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "========================================"
echo " TechNova - Destroy AWS"
echo "========================================"

PUBLIC_IP=$(curl -s https://checkip.amazonaws.com | tr -d '\n')
SSH_CIDR="${PUBLIC_IP}/32"

cd "${ROOT_DIR}/infra"

terraform destroy \
  -auto-approve \
  -var="db_password=${DB_PASSWORD}" \
  -var="ssh_cidr=${SSH_CIDR}" \
  -var="repository_url=https://github.com/iHawlKz7/prova-primeiro-bimestre-devops.git"

echo
echo "Infraestrutura principal destruída."
echo "Backend S3/DynamoDB mantido temporariamente."