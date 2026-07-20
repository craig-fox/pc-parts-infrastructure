#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "Deploying PC Parts Store Frontend"
echo "========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

BUCKET_NAME=$(terraform -chdir="${TERRAFORM_DIR}" output -raw bucket_name)
DISTRIBUTION_ID=$(terraform -chdir="${TERRAFORM_DIR}" output -raw cloudfront_distribution_id)

FRONTEND_DIR="${SCRIPT_DIR}/../../pc-parts-store-ui"

echo ""
echo "Building React application..."
cd "${FRONTEND_DIR}"
npm run build

echo ""
echo "Uploading files to S3 bucket: ${BUCKET_NAME}"
aws s3 sync dist/ "s3://${BUCKET_NAME}" --delete

echo ""
echo "Creating CloudFront invalidation..."
aws cloudfront create-invalidation \
    --distribution-id "${DISTRIBUTION_ID}" \
    --paths "/*"

echo ""
echo "Deployment complete!"
echo ""
echo "Frontend URL:"
terraform -chdir="${TERRAFORM_DIR}" output frontend_url