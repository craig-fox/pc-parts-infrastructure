#!/usr/bin/env bash

set -euo pipefail

REGION="ap-southeast-2"

CLUSTER="pc-parts-store-frontend-dev-cluster"
TASK_DEFINITION="pc-parts-store-frontend-dev-db-bootstrap"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${INFRA_DIR}/terraform"

echo "========================================"
echo "Bootstrapping databases"
echo "========================================"
echo ""

echo "Reading current infrastructure IDs from Terraform..."

SUBNETS_JSON=$(terraform -chdir="${TERRAFORM_DIR}" output -json private_subnet_ids)

SUBNET_1=$(echo "${SUBNETS_JSON}" | jq -r '.[0]')
SUBNET_2=$(echo "${SUBNETS_JSON}" | jq -r '.[1]')

SECURITY_GROUP=$(terraform -chdir="${TERRAFORM_DIR}" output -raw ecs_security_group_id)

echo "Private subnets:"
echo "  ${SUBNET_1}"
echo "  ${SUBNET_2}"

echo "ECS security group: ${SECURITY_GROUP}"
echo ""

echo "Starting database bootstrap task..."

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEFINITION" \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={subnets=[\"${SUBNET_1}\",\"${SUBNET_2}\"],securityGroups=[\"${SECURITY_GROUP}\"],assignPublicIp=\"DISABLED\"}" \
  --region "$REGION" \
  --query 'tasks[0].taskArn' \
  --output text)

if [[ -z "$TASK_ARN" || "$TASK_ARN" == "None" ]]; then
  echo "ERROR: Failed to start database bootstrap task."
  exit 1
fi

TASK_ID="${TASK_ARN##*/}"

echo "Bootstrap task started: $TASK_ID"
echo "Waiting for task to complete..."

aws ecs wait tasks-stopped \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ID" \
  --region "$REGION"

RESULT=$(aws ecs describe-tasks \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ID" \
  --region "$REGION" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

if [[ "$RESULT" != "0" ]]; then
  echo "ERROR: Database bootstrap failed with exit code $RESULT."
  echo

  echo "Task details:"

  aws ecs describe-tasks \
    --cluster "$CLUSTER" \
    --tasks "$TASK_ID" \
    --region "$REGION" \
    --query 'tasks[0].{StopCode:stopCode,StoppedReason:stoppedReason,ExitCode:containers[0].exitCode,Reason:containers[0].reason}' \
    --output table

  exit 1
fi

echo "Database bootstrap completed successfully."
echo "Databases are ready for the application services."
