# PC Parts Store Infrastructure

Infrastructure as Code (IaC) for the PC Parts Store project.

This repository contains the Terraform configuration and deployment scripts used to provision and manage the AWS infrastructure that supports the application.

## Repositories

The PC Parts Store project is split across three repositories:

| Repository | Purpose |
|------------|---------|
| `pc-parts-store-ui` | React frontend |
| `pc-parts-store-api` | Spring Boot backend |
| `pc-parts-store-infrastructure` | Terraform infrastructure and deployment scripts |

## Technologies

- Terraform
- AWS
- Amazon S3
- Amazon CloudFront
- AWS CLI

Additional AWS services will be added as the backend is deployed.

## Repository Structure

```
terraform/
    frontend/
        versions.tf
        providers.tf
        variables.tf
        locals.tf
        main.tf
        outputs.tf

scripts/
```

## Current Scope

The initial version of this repository provisions the infrastructure required to host the React frontend.

This includes:

- S3 bucket
- CloudFront distribution
- Supporting AWS resources

## Running pc-parts-store-ui
### Prerequisites

Before deploying, ensure you have the following installed:

Terraform 1.6 or later
AWS CLI v2
Node.js 22 or later
npm

You will also need:

An AWS account
AWS credentials configured locally (for example using aws configure)
Permission to create S3, CloudFront and IAM resources

### Clone the repositories

Clone both repositories into the same parent directory:

projects/
├── pc-parts-infrastructure/
└── pc-parts-store-ui/
Configure AWS

Verify that your credentials are working:

aws sts get-caller-identity
### Deploy the infrastructure

From the terraform directory:

terraform init
terraform plan
terraform apply

Terraform will provision the required AWS resources and output values including the CloudFront URL.

### Deploy the frontend

From the root of the infrastructure repository:

./scripts/deploy-frontend.sh

The deployment script will:

Build the React application.
Upload the production build to the S3 bucket.
Create a CloudFront invalidation.
Display the CloudFront URL.

After the deployment completes, open the displayed CloudFront URL in your browser.

### Updating the application

Whenever changes are made to the React application:

./scripts/deploy-frontend.sh

The script rebuilds the application, uploads the changed files, and refreshes the CloudFront cache.

### Destroying the infrastructure

To remove all AWS resources created by Terraform:

terraform destroy

Ensure the S3 bucket is empty before destroying the infrastructure if Terraform reports that the bucket cannot be deleted.

## Future Enhancements

As the backend evolves, this repository will also provision infrastructure for:

- Amazon ECS
- Amazon ECR
- Amazon RDS (PostgreSQL)
- IAM Roles and Policies
- VPC Networking
- Application Load Balancer
- CloudWatch
- Secrets Manager

## License

This project is provided for learning and portfolio purposes.