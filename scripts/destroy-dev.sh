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

echo "WARNING: This will destroy the development"
echo "AWS environment, except ECR repositories."
echo ""

echo "This includes:"
echo "  - ECS resources"
echo "  - RDS PostgreSQL"
echo "  - ALB"
echo "  - NAT Gateway"
echo "  - VPC and subnets"
echo "  - Secrets Manager secrets"
echo "  - CloudFront distribution"
echo "  - S3 frontend bucket"
echo ""
echo "The following will be RETAINED:"
echo "  - ECR repositories"
echo "  - ECR images"
echo ""

read -r -p "Type 'destroy-dev' to continue: " confirmation

if [[ "${confirmation}" != "destroy-dev" ]]; then
    echo ""
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "Removing ECR repositories from Terraform state..."
echo ""

terraform -chdir="${TERRAFORM_DIR}" state list \
    | grep '^aws_ecr_repository.service\[' \
    | while read -r resource; do
        echo "  Retaining ${resource}"
        terraform -chdir="${TERRAFORM_DIR}" state rm "${resource}"
    done

echo ""
echo "Destroying remaining development environment..."
echo ""

terraform -chdir="${TERRAFORM_DIR}" destroy \
    -var="environment=dev"

echo ""
echo "========================================"
echo "Development environment destroyed."
echo "ECR repositories and images retained."
echo "========================================"
echo ""