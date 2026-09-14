#!/usr/bin/env bash

set -euo pipefail

REGION="ap-southeast-2"
CLUSTER="pc-parts-store-frontend-dev-cluster"
TASK_DEFINITION="pc-parts-store-frontend-dev-db-bootstrap"
SUBNETS="subnet-012539010d7c40803,subnet-037faf7b8a280d1f3"
SECURITY_GROUP="sg-0947158b9eafe1454"

echo "Starting database bootstrap task..."

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEFINITION" \
  --launch-type FARGATE \
  --platform-version LATEST \
  --network-configuration "awsvpcConfiguration={
    subnets=[$(printf '"%s","%s"' \
      "${SUBNETS%%,*}" \
      "${SUBNETS##*,}")],
    securityGroups=[\"$SECURITY_GROUP\"],
    assignPublicIp=\"DISABLED\"
  }" \
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

