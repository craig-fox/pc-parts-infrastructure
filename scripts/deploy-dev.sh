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

# The ECR repositories are managed by Terraform, but we need
# them before we can build and push the application images.
#
# Therefore bootstrap only the ECR resources first.

terraform -chdir="${TERRAFORM_DIR}" apply \
    -auto-approve \
    -target='aws_ecr_repository.service' \
    -var="product_image_tag=${IMAGE_TAG}" \
    -var="customer_image_tag=${IMAGE_TAG}" \
    -var="order_image_tag=${IMAGE_TAG}" \
    -var="inventory_image_tag=${IMAGE_TAG}" \
    -var="gateway_image_tag=${IMAGE_TAG}" \
    -var="authentication_image_tag=${IMAGE_TAG}" \
    -var="environment=dev"


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

echo
echo "========================================"
echo " Building frontend"
echo "========================================"

cd "${UI_DIR}"

npm ci
npm run build


FRONTEND_BUCKET="$(
    terraform -chdir="${TERRAFORM_DIR}" output -raw bucket_name
)"

echo "==> Uploading frontend to s3://${FRONTEND_BUCKET}"

aws s3 sync \
    dist/ \
    "s3://${FRONTEND_BUCKET}/" \
    --delete \
    --region "${AWS_REGION}"


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
