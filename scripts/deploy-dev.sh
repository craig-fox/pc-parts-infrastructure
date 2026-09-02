#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(cd "${INFRA_DIR}/.." && pwd)"

API_DIR="${PROJECT_DIR}/pc-parts-store-api"
UI_DIR="${PROJECT_DIR}/pc-parts-store-ui"
TERRAFORM_DIR="${INFRA_DIR}/terraform"

AWS_REGION="ap-southeast-2"
ECR_REGISTRY="530290262907.dkr.ecr.${AWS_REGION}.amazonaws.com"


# Use the current Git commit as the immutable image tag.
IMAGE_TAG="$(git -C "${API_DIR}" rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"

echo ""
echo "========================================"
echo "PC Parts Store - Development Deployment"
echo "========================================"
echo ""

echo "Image tag: ${IMAGE_TAG}"
echo ""

# ----------------------------------------
# Terraform
# ----------------------------------------

echo "Applying infrastructure..."
echo ""

terraform -chdir="${TERRAFORM_DIR}" apply

echo ""

# ----------------------------------------
# ECR authentication
# ----------------------------------------

echo "Logging in to ECR..."
echo ""

aws ecr get-login-password \
    --region "${AWS_REGION}" |
    docker login \
        --username AWS \
        --password-stdin "${ECR_REGISTRY}"

echo ""

# ----------------------------------------
# Backend services
# ----------------------------------------

deploy_service() {
    local service_name="$1"
    local repository_name="$2"

    local service_dir="${API_DIR}/${service_name}"
    local repository_url="${ECR_REGISTRY}/${repository_name}"

    echo "========================================"
    echo "Deploying ${service_name}"
    echo "========================================"
    echo ""

    echo "Building JAR..."
    mvn -f "${API_DIR}/pom.xml" -pl "${service_name}" -am clean package

    echo ""
    echo "Building Docker image..."
    docker build \
        --platform linux/amd64 \
        -t "${repository_url}:${IMAGE_TAG}" \
        "${service_dir}"

    echo ""
    echo "Pushing Docker image..."
    docker push "${repository_url}:${IMAGE_TAG}"

    echo ""
}

# Product service is currently the only deployed backend service.
deploy_service \
    "product-service" \
    "pc-parts-store-product-service"

terraform -chdir="${TERRAFORM_DIR}" apply \
    -var="image_tag=${IMAGE_TAG}"

BUCKET_NAME="$(terraform -chdir="${TERRAFORM_DIR}" output -raw bucket_name)"
DISTRIBUTION_ID="$(terraform -chdir="${TERRAFORM_DIR}" output -raw cloudfront_distribution_id)"

# ----------------------------------------
# Frontend
# ----------------------------------------

echo "========================================"
echo "Building frontend"
echo "========================================"
echo ""

cd "${UI_DIR}"

npm run build

echo ""
echo "Uploading files to S3 bucket: ${BUCKET_NAME}"
echo ""

aws s3 sync dist/ "s3://${BUCKET_NAME}" --delete

echo ""
echo "Creating CloudFront invalidation..."
echo ""

aws cloudfront create-invalidation \
    --distribution-id "${DISTRIBUTION_ID}" \
    --paths "/*"

echo ""
echo "========================================"
echo "Deployment complete!"
echo "========================================"
echo ""

echo "Frontend URL:"
terraform -chdir="${TERRAFORM_DIR}" output frontend_url

echo ""
```
