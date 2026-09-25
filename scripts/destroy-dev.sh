#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${INFRA_DIR}/terraform/application"


echo ""
echo "========================================"
echo "PC Parts Store - Destroy Development"
echo "========================================"
echo ""

echo "WARNING: This will destroy the development"
echo "application infrastructure. Persistent infrastructure"
echo "and data will NOT be affected."
echo ""

echo "This includes:"
echo "  - ECS services and task definitions"
echo "  - ALB"
echo "  - Cloud Map service discovery"
echo "  - CloudFront distribution"
echo "  - S3 frontend bucket"
echo "  - Route 53 application records"
echo "  - ACM certificates"
echo "  - Application IAM resources"
echo ""

echo "The following will be RETAINED:"
echo "  - ECR repositories"
echo "  - ECR images"
echo "  - RDS PostgreSQL and application data"
echo "  - VPC and networking"
echo "  - Persistent Secrets Manager secrets"
echo "  - Management instance"

read -r -p "Type 'destroy-dev' to continue: " confirmation

if [[ "${confirmation}" != "destroy-dev" ]]; then
    echo ""
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo "Removing ECR repositories from Terraform state..."
echo ""

ECR_RESOURCES="$(terraform -chdir="${TERRAFORM_DIR}" state list \
    | grep '^aws_ecr_repository.service\[' || true)"

if [[ -n "${ECR_RESOURCES}" ]]; then
    while read -r resource; do
        echo "  Retaining ${resource}"
        terraform -chdir="${TERRAFORM_DIR}" state rm "${resource}"
    done <<< "${ECR_RESOURCES}"
else
    echo "  No ECR repositories found in Terraform state."
fi

echo ""
echo "Destroying remaining development environment..."
echo ""

TERRAFORM_IMAGE_VARS=(
    "-var=product_image_tag=destroy"
    "-var=customer_image_tag=destroy"
    "-var=order_image_tag=destroy"
    "-var=inventory_image_tag=destroy"
    "-var=shipping_image_tag=destroy"
    "-var=payment_image_tag=destroy"
    "-var=gateway_image_tag=destroy"
    "-var=authentication_image_tag=destroy"
    "-var=environment=dev"
)

terraform -chdir="${TERRAFORM_DIR}" destroy \
    "${TERRAFORM_IMAGE_VARS[@]}"

echo ""
echo "========================================"
echo "Development application infrastructure destroyed."
echo "ECR repositories and images retained."
echo "========================================"
echo ""
