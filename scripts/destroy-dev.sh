#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${INFRA_DIR}/terraform"

echo ""
echo "========================================"
echo "PC Parts Store - Destroy Development"
echo "========================================"
echo ""

echo "WARNING: This will destroy the entire"
echo "development AWS environment."
echo ""
echo "This includes:"
echo "  - ECS resources"
echo "  - RDS PostgreSQL"
echo "  - ALB"
echo "  - NAT Gateway"
echo "  - VPC and subnets"
echo "  - ECR repositories and images"
echo "  - Secrets Manager secrets"
echo "  - CloudFront distribution"
echo "  - S3 frontend bucket"
echo ""

read -r -p "Type 'destroy-dev' to continue: " confirmation

if [[ "${confirmation}" != "destroy-dev" ]]; then
    echo ""
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "Planning destruction..."
echo ""

terraform -chdir="${TERRAFORM_DIR}" destroy \
    -var="environment=dev"

echo ""
read -r -p "Proceed with destruction? [y/N] " confirmation

if [[ ! "${confirmation}" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "Destroying development environment..."
echo ""

terraform -chdir="${TERRAFORM_DIR}" destroy \
    -var="environment=dev" \
    -auto-approve

echo ""
echo "========================================"
echo "Development environment destroyed."
echo "========================================"
echo ""