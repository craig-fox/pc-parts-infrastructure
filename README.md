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