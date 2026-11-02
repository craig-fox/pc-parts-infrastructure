#!/usr/bin/env bash
set -euo pipefail

# Resolve the infrastructure repository root, regardless of where this
# script is located within that repository.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"
API_DIR="$(cd "${INFRA_DIR}/.." && pwd)/pc-parts-store-api"

REGION="ap-southeast-2"
AWS_ACCOUNT_ID="530290262907"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# The tag is shared by every service and can be reused by restore-all.sh.
IMAGE_TAG="$(git -C "${API_DIR}" rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)"
IMAGE_TAG_FILE="${SCRIPT_DIR}/.image-tag"

SERVICES=(
    "product-service:pc-parts-store-product-service"
    "authentication-service:pc-parts-store-authentication-service"
    "customer-service:pc-parts-store-customer-service"
    "order-service:pc-parts-store-order-service"
    "inventory-service:pc-parts-store-inventory-service"
    "shipping-service:pc-parts-store-shipping-service"
    "payment-service:pc-parts-store-payment-service"
    "api-gateway:pc-parts-store-api-gateway"
)

for command in aws docker mvn git; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: ${command}" >&2
        exit 1
    fi
done

if [[ ! -d "${API_DIR}" ]]; then
    echo "ERROR: API project directory not found: ${API_DIR}" >&2
    exit 1
fi

echo "Infrastructure directory: ${INFRA_DIR}"
echo "API directory:            ${API_DIR}"
echo "AWS region:               ${REGION}"
echo "Image tag:                ${IMAGE_TAG}"
echo

echo "Checking AWS identity..."
aws sts get-caller-identity --region "${REGION}" >/dev/null

echo "Logging in to ECR..."
aws ecr get-login-password --region "${REGION}" \
    | docker login \
        --username AWS \
        --password-stdin "${ECR_REGISTRY}"

# ECR repositories are expected to survive destroy-all.sh.
# Fail early if any repository is missing.
echo "Checking ECR repositories..."
for service in "${SERVICES[@]}"; do
    IFS=":" read -r module repository <<< "${service}"

    if ! aws ecr describe-repositories \
        --repository-names "${repository}" \
        --region "${REGION}" >/dev/null 2>&1; then
        echo "ERROR: ECR repository not found: ${repository}" >&2
        echo "Create/restore the ECR repositories before running build-all.sh." >&2
        exit 1
    fi
done



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

# Save the tag only after all calls succeed
printf '%s\n' "${IMAGE_TAG}" > "${IMAGE_TAG_FILE}"

echo
echo "All service images built and pushed successfully."
echo "Image tag saved to: ${IMAGE_TAG_FILE}"
echo "Image tag:          ${IMAGE_TAG}"
