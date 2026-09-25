#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(cd "${INFRA_DIR}/.." && pwd)"

API_DIR="${PROJECT_DIR}/pc-parts-store-api"
UI_DIR="${PROJECT_DIR}/pc-parts-store-ui"
TERRAFORM_DIR="${INFRA_DIR}/terraform/application"

AWS_REGION="ap-southeast-2"
ECR_REGISTRY="530290262907.dkr.ecr.${AWS_REGION}.amazonaws.com"

IMAGE_TAG="$(git -C "${API_DIR}" rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"

echo
echo "========================================"
echo " PC Parts Store - Dev Deployment"
echo "========================================"
echo
echo "Image tag: ${IMAGE_TAG}"
echo


# ------------------------------------------------------------
# AWS / ECR authentication
# ------------------------------------------------------------

echo "==> Authenticating to ECR"

aws ecr get-login-password \
    --region "${AWS_REGION}" \
    | docker login \
        --username AWS \
        --password-stdin "${ECR_REGISTRY}"


# ------------------------------------------------------------
# ECR repository bootstrap
# ------------------------------------------------------------


echo
echo "==> Ensuring ECR repositories exist"

# ECR repositories are retained when the development
# infrastructure is destroyed. If they were removed from
# Terraform state during teardown, import them back into
# state before running the ECR bootstrap apply.

TERRAFORM_IMAGE_VARS=(
    "-var=product_image_tag=${IMAGE_TAG}"
    "-var=customer_image_tag=${IMAGE_TAG}"
    "-var=order_image_tag=${IMAGE_TAG}"
    "-var=inventory_image_tag=${IMAGE_TAG}"
    "-var=shipping_image_tag=${IMAGE_TAG}"
    "-var=payment_image_tag=${IMAGE_TAG}"
    "-var=gateway_image_tag=${IMAGE_TAG}"
    "-var=authentication_image_tag=${IMAGE_TAG}"
    "-var=environment=dev"
)

ECR_REPOSITORIES=(
    "gateway:pc-parts-store-api-gateway"
    "authentication:pc-parts-store-authentication-service"
    "customer:pc-parts-store-customer-service"
    "order:pc-parts-store-order-service"
    "product:pc-parts-store-product-service"
    "inventory:pc-parts-store-inventory-service"
    "payment:pc-parts-store-payment-service"
    "shipping:pc-parts-store-shipping-service"
)

for entry in "${ECR_REPOSITORIES[@]}"; do
    resource_key="${entry%%:*}"
    repository_name="${entry#*:}"
    resource="aws_ecr_repository.service[\"${resource_key}\"]"

    if terraform -chdir="${TERRAFORM_DIR}" state show "${resource}" >/dev/null 2>&1; then
        echo "  ${repository_name}: already managed by Terraform"
    else
        echo "  ${repository_name}: importing existing repository"

        terraform -chdir="${TERRAFORM_DIR}" import \
            "${TERRAFORM_IMAGE_VARS[@]}" \
            "${resource}" \
            "${repository_name}"
    fi
done

terraform -chdir="${TERRAFORM_DIR}" apply \
    -auto-approve \
    -target='aws_ecr_repository.service' \
    "${TERRAFORM_IMAGE_VARS[@]}"


# ------------------------------------------------------------
# Build and push services
# ------------------------------------------------------------

deploy_service() {
    local service_name="$1"
    local repository_name="$2"

    local service_dir="${API_DIR}/${service_name}"
    local repository_url="${ECR_REGISTRY}/${repository_name}"

    echo
    echo "========================================"
    echo " Deploying ${service_name}"
    echo "========================================"

    echo "==> Building Maven module"

    mvn -f "${API_DIR}/pom.xml" \
        -pl "${service_name}" \
        -am \
        clean package

    echo "==> Building Docker image"

    docker build \
        --platform linux/arm64 \
        -t "${repository_url}:${IMAGE_TAG}" \
        "${service_dir}"

    echo "==> Pushing Docker image"

    docker push "${repository_url}:${IMAGE_TAG}"
}


deploy_service \
    "product-service" \
    "pc-parts-store-product-service"

deploy_service \
    "authentication-service" \
    "pc-parts-store-authentication-service"

deploy_service \
    "customer-service" \
    "pc-parts-store-customer-service"

deploy_service \
    "order-service" \
    "pc-parts-store-order-service"

deploy_service \
    "inventory-service" \
    "pc-parts-store-inventory-service"

deploy_service \
    "shipping-service" \
    "pc-parts-store-shipping-service"

deploy_service \
    "payment-service" \
    "pc-parts-store-payment-service"

deploy_service \
    "api-gateway" \
    "pc-parts-store-api-gateway"


# ------------------------------------------------------------
# Terraform infrastructure deployment
# ------------------------------------------------------------

echo
echo "========================================"
echo " Applying infrastructure"
echo "========================================"

terraform -chdir="${TERRAFORM_DIR}" apply \
    -auto-approve \
    -var="environment=dev" \
    -var="product_image_tag=${IMAGE_TAG}" \
    -var="customer_image_tag=${IMAGE_TAG}" \
    -var="order_image_tag=${IMAGE_TAG}" \
    -var="inventory_image_tag=${IMAGE_TAG}" \
    -var="shipping_image_tag=${IMAGE_TAG}" \
    -var="payment_image_tag=${IMAGE_TAG}" \
    -var="gateway_image_tag=${IMAGE_TAG}" \
    -var="authentication_image_tag=${IMAGE_TAG}"


# ------------------------------------------------------------
# Database bootstrap
# ------------------------------------------------------------

echo
echo "==> Bootstrapping databases"

"${SCRIPT_DIR}/bootstrap-db.sh"


# ------------------------------------------------------------
# Frontend
# ------------------------------------------------------------

"${SCRIPT_DIR}/deploy-frontend.sh"

# ------------------------------------------------------------
# CloudFront
# ------------------------------------------------------------

echo
echo "==> Invalidating CloudFront cache"

CLOUDFRONT_DISTRIBUTION_ID="$(
    terraform -chdir="${TERRAFORM_DIR}" output -raw cloudfront_distribution_id
)"

aws cloudfront create-invalidation \
    --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
    --paths "/*"


# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

echo
echo "========================================"
echo " Deployment complete"
echo "========================================"
echo
echo "Image tag: ${IMAGE_TAG}"
echo
