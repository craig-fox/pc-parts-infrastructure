#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(cd "${INFRA_DIR}/.." && pwd)"

UI_DIR="${PROJECT_DIR}/pc-parts-store-ui"
TERRAFORM_DIR="${INFRA_DIR}/terraform"
APPLICATION_TERRAFORM_DIR="${TERRAFORM_DIR}/application"
AWS_REGION="ap-southeast-2"

echo
echo "========================================"
echo " PC Parts Store - Frontend Deployment"
echo "========================================"
echo

echo "==> Building frontend"

cd "${UI_DIR}"

npm ci
npm run build

echo
echo "==> Getting frontend S3 bucket"

FRONTEND_BUCKET="$(
    terraform -chdir="${APPLICATION_TERRAFORM_DIR}" output -raw bucket_name
)"

echo "==> Uploading frontend to s3://${FRONTEND_BUCKET}"

aws s3 sync \
    dist/ \
    "s3://${FRONTEND_BUCKET}/" \
    --delete \
    --region "${AWS_REGION}"

echo
echo "==> Invalidating CloudFront cache"

CLOUDFRONT_DISTRIBUTION_ID="$(
    terraform -chdir="${APPLICATION_TERRAFORM_DIR}" output -raw cloudfront_distribution_id
)"

aws cloudfront create-invalidation \
    --distribution-id "${CLOUDFRONT_DISTRIBUTION_ID}" \
    --paths "/*"

echo
echo "========================================"
echo " Frontend deployment complete"
echo "========================================"
echo
echo "URL: https://pcparts.craigfox.dev/"
echo