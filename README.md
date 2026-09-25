# PC Parts Store Infrastructure

**Version: 1.2.0**

Infrastructure as Code (IaC) for the PC Parts Store platform.

This repository contains the Terraform configuration and deployment scripts used to provision and manage the AWS infrastructure supporting the PC Parts Store backend and frontend.

Version 1.2.0 represents the first fully deployed AWS version of the platform, including the networking, database, service discovery, ECS/Fargate services, API load balancing, secrets, logging, container registries, and frontend hosting required to run the application in a production-shaped AWS environment.

---

## Overview

The PC Parts Store project is split across several repositories:

| Repository                | Purpose                                     |
| ------------------------- | ------------------------------------------- |
| `pc-parts-store-api`      | Spring Boot microservices backend           |
| `pc-parts-store-ui`       | React frontend                              |
| `pc-parts-store-e2e`      | End-to-end tests                            |
| `pc-parts-infrastructure` | Terraform infrastructure and AWS deployment |

The infrastructure repository is responsible for the AWS resources required to run the platform.

The application is deployed to AWS using:

* Amazon ECS with AWS Fargate
* Amazon ECR
* Amazon VPC
* AWS Cloud Map
* Application Load Balancer
* Amazon RDS for PostgreSQL
* AWS Secrets Manager
* Amazon CloudWatch
* Amazon S3
* Amazon CloudFront
* IAM

The AWS deployment uses the `ap-southeast-2` region.

---

## Architecture

The AWS deployment consists of two main application paths.

### Frontend

```text
Browser
   |
   v
CloudFront
   |
   v
S3
   |
   v
React application
```

The React application is built from the `pc-parts-store-ui` repository and deployed to an S3 bucket. CloudFront provides the public distribution and caching layer.

### Backend

```text
Browser / React UI
        |
        v
Application Load Balancer
        |
        v
API Gateway
   ECS / Fargate
        |
        +-----------------------+
        |                       |
        v                       v
 Authentication          Customer / Product
        |                  / Inventory
        |                       |
        +----------+------------+
                   |
                   v
             Order Service
             /     |      \
            /      |       \
           v       v        v
      Shipping  Payment  Inventory
            \      |       /
             \     |      /
              v    v     v
              RDS PostgreSQL
```

The backend services run as independent ECS/Fargate services.

AWS Cloud Map provides service discovery between ECS services. The services communicate using internal service names rather than public endpoints.

---

## Terraform Structure

The Terraform configuration is separated into two areas:

```text
terraform/
├── persistent/
└── application/
```

### Persistent infrastructure

The `persistent` configuration contains infrastructure that should generally have a longer lifecycle than the application deployment.

This includes resources such as:

* VPC and networking
* Public and private subnets
* Security groups
* RDS PostgreSQL
* Database subnet groups
* Persistent Secrets Manager resources
* Supporting IAM resources

The intention is to allow the application infrastructure to be destroyed and recreated without unnecessarily destroying persistent data infrastructure.

### Application infrastructure

The `application` configuration contains resources associated with deploying the current application version.

This includes:

* ECR repositories
* ECS cluster
* ECS task definitions
* ECS services
* AWS Fargate tasks
* AWS Cloud Map service discovery
* Application Load Balancer
* CloudWatch log groups
* ECS IAM roles
* Frontend S3 bucket
* CloudFront distribution
* Supporting application IAM resources

This separation makes it possible to manage persistent resources independently from application deployments.

---

## Repository Structure

The repository is organised approximately as follows:

```text
pc-parts-infrastructure/
├── terraform/
│   ├── persistent/
│   │   ├── versions.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── locals.tf
│   │   ├── networking.tf
│   │   ├── rds.tf
│   │   ├── secrets.tf
│   │   ├── outputs.tf
│   │   └── ...
│   │
│   └── application/
│       ├── versions.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── locals.tf
│       ├── ecr.tf
│       ├── ecs.tf
│       ├── alb.tf
│       ├── cloud-map.tf
│       ├── cloudwatch.tf
│       ├── frontend.tf
│       ├── iam.tf
│       ├── outputs.tf
│       └── ...
│
├── scripts/
│   ├── ...
│   └── deploy-frontend.sh
│
└── README.md
```

The exact Terraform file names may vary as the infrastructure evolves; the important distinction is between persistent and application infrastructure.

---

## AWS Resources

### Networking

The persistent Terraform configuration provisions the network required by the application, including:

* VPC
* Public subnets
* Private subnets
* Internet/NAT routing as required
* Security groups
* Subnet groups

Application services run inside the VPC rather than being directly exposed to the public internet.

### ECS / Fargate

The backend services run as ECS services using AWS Fargate.

The deployed services include:

* authentication-service
* customer-service
* product-service
* inventory-service
* order-service
* payment-service
* shipping-service
* api-gateway

The services are deployed using ARM64-compatible container images.

The current deployment is intentionally small and is designed as a production-shaped portfolio environment rather than a high-capacity production system.

### ECR

Each containerised service has an Amazon ECR repository.

The deployment process builds Docker images locally and pushes them to ECR before updating the ECS services.

ECR repositories are intentionally retained when application infrastructure is destroyed.

This means application infrastructure can be recreated without losing the existing container repositories and images.

### Cloud Map

AWS Cloud Map provides private service discovery for ECS services.

For example, internal services can communicate using service discovery names such as:

```text
http://payment-service.pc-parts-store.dev:8080
http://shipping-service.pc-parts-store.dev:8080
```

This avoids coupling the services to dynamically assigned ECS task addresses.

### Application Load Balancer

The Application Load Balancer provides the public entry point for the backend.

The ALB routes traffic to the API Gateway running in ECS.

The API Gateway is then responsible for routing requests to the individual backend services.

### RDS PostgreSQL

The application uses Amazon RDS PostgreSQL for persistent data storage.

The current database infrastructure uses:

* PostgreSQL 17
* `t4g.micro`
* 20 GB initial storage
* gp3 storage
* automatic storage growth up to 100 GB
* encryption enabled
* database name `pcparts`

The microservices use separate logical databases for their own data.

### Secrets Manager

Database credentials and other sensitive configuration are stored in AWS Secrets Manager rather than being committed to Terraform configuration or container images.

ECS task definitions reference the required secrets when starting application containers.

### CloudWatch

CloudWatch is used for ECS application logging.

The application services write container logs to CloudWatch log groups, providing a central location for inspecting AWS deployment and runtime issues.

### S3 and CloudFront

The React frontend is hosted using:

* Amazon S3
* Amazon CloudFront

The S3 bucket contains the production React build.

CloudFront provides the public distribution and caching layer.

---

## Prerequisites

Before deploying the infrastructure, ensure the following are installed:

* Terraform 1.6 or later
* AWS CLI v2
* Docker
* Node.js 22 or later
* npm

You will also need:

* An AWS account
* AWS credentials configured locally
* Sufficient AWS permissions to create the required resources
* Access to the `pc-parts-store-api` repository
* Access to the `pc-parts-store-ui` repository

Verify AWS credentials with:

```bash
aws sts get-caller-identity
```

---

## AWS Region

The infrastructure is currently deployed to:

```text
ap-southeast-2
```

The Terraform provider configuration and resource definitions use this region.

---

## Deployment Model

The deployment is divided into persistent infrastructure and application infrastructure.

A typical deployment lifecycle is:

```text
1. Deploy persistent infrastructure
             |
             v
2. Build application Docker images
             |
             v
3. Push images to ECR
             |
             v
4. Apply application Terraform
             |
             v
5. ECS deploys updated tasks
             |
             v
6. Verify CloudWatch logs and service health
             |
             v
7. Run end-to-end tests
```

This separation allows application changes to be deployed without repeatedly recreating the underlying database and network infrastructure.

---

## Deploying Persistent Infrastructure

From the persistent Terraform directory:

```bash
cd terraform/persistent
terraform init
terraform plan
terraform apply
```

The persistent infrastructure should generally be created before deploying the application infrastructure.

The outputs provide values required by the application infrastructure and deployment process.

---

## Deploying Application Infrastructure

From the application Terraform directory:

```bash
cd terraform/application
terraform init
terraform plan
terraform apply
```

The application infrastructure provisions or updates the ECS, ECR, Cloud Map, ALB, CloudWatch, frontend and supporting resources.

---

## Container Deployment

The backend services are built as Docker images.

The deployment process is:

```text
Source code
    |
    v
Docker build
    |
    v
ARM64 image
    |
    v
Amazon ECR
    |
    v
ECS task definition
    |
    v
ECS/Fargate service
```

After a new image is pushed to ECR, the corresponding ECS service is updated so that new tasks use the new image.

---

## Frontend Deployment

The React application is maintained in the separate `pc-parts-store-ui` repository.

The infrastructure repository provides the AWS resources required to host it.

The frontend deployment script can be run from the infrastructure repository:

```bash
./scripts/deploy-frontend.sh
```

The deployment process:

1. Builds the React application.
2. Uploads the production build to S3.
3. Creates a CloudFront invalidation.
4. Displays the frontend URL.

The public frontend is served through CloudFront rather than directly from S3.

---

## Application Configuration

The ECS services receive environment-specific configuration from the infrastructure.

Service-to-service communication uses AWS Cloud Map service discovery.

Examples include:

```text
CUSTOMER_SERVICE_URL
PRODUCT_SERVICE_URL
INVENTORY_SERVICE_URL
PAYMENT_SERVICE_URL
SHIPPING_SERVICE_URL
```

The API Gateway uses these internal service URLs to route requests to the backend services.

Sensitive values such as database credentials are supplied through Secrets Manager.

---

## Database Architecture

The backend consists of several services with separate persistence responsibilities.

The current databases include:

```text
customerdb
productdb
orderdb
inventorydb
paymentdb
shippingdb
```

Each service manages its own database schema and migrations.

Database schema changes are managed by Flyway in the corresponding Spring Boot service.

---

## Destroying Infrastructure

Persistent and application infrastructure should be treated differently.

### Destroy application infrastructure

From:

```bash
cd terraform/application
```

run:

```bash
terraform destroy
```

The application infrastructure is designed so that ECR repositories can be retained across application destroy/redeploy cycles.

### Destroy persistent infrastructure

From:

```bash
cd terraform/persistent
```

run:

```bash
terraform destroy
```

This should be treated with considerably more caution because it includes resources such as the RDS database and network infrastructure.

Destroying persistent infrastructure can result in permanent data loss.

---

## ECR Repository Lifecycle

ECR repositories are intentionally retained across application infrastructure rebuilds.

The deployment workflow therefore supports:

```text
Application destroy
       |
       v
ECR repositories remain
       |
       v
Application infrastructure recreated
       |
       v
Existing repositories imported/reused
```

This avoids unnecessarily rebuilding the container registry infrastructure every time the ECS application stack is recreated.

---

## Verification

After deployment, the infrastructure should be verified at several levels.

### Terraform

```bash
terraform plan
```

Confirm that the resulting changes are expected.

### ECS

Check that the expected ECS services have running tasks.

### CloudWatch

Inspect the application logs for:

* startup failures
* database connection errors
* service discovery errors
* authentication errors
* API Gateway routing errors

### AWS endpoints

Verify the public API and frontend endpoints.

The current public endpoints are:

```text
Frontend:
https://pcparts.craigfox.dev

API:
https://api.pcparts.craigfox.dev
```

### End-to-end tests

The `pc-parts-store-e2e` repository provides the end-to-end test suite for validating the deployed platform.

The AWS deployment should be considered verified only after the relevant E2E tests pass.

---

## Infrastructure and Application Versions

The infrastructure repository uses its own version independently of the application repositories.

For the 1.2.0 platform milestone:

```text
pc-parts-store-api             1.2.0
pc-parts-infrastructure        1.2.0
pc-parts-store-ui              1.1.1
pc-parts-store-e2e             1.1.3
```

The infrastructure version identifies the Terraform configuration associated with the corresponding infrastructure milestone.

Git tags are used to identify released versions:

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

Terraform's own `required_version` setting remains separate from the project version and identifies the Terraform CLI versions supported by the configuration.

---

## Version 1.2.0

Version 1.2.0 represents the first complete AWS deployment of the PC Parts Store platform.

Major infrastructure capabilities introduced for this milestone include:

* AWS VPC networking
* Public and private subnets
* Security groups
* Amazon ECS
* AWS Fargate
* ARM64 container deployment
* Amazon ECR
* AWS Cloud Map
* Application Load Balancer
* Amazon RDS PostgreSQL
* AWS Secrets Manager
* Amazon CloudWatch
* Amazon S3
* Amazon CloudFront
* ECS IAM roles and policies
* Separation of persistent and application Terraform
* Retained ECR repositories across application redeployments
* AWS deployment of the backend microservices
* AWS deployment of the React frontend

---

## Relationship to the Application

The infrastructure supports the Spring Boot microservices in `pc-parts-store-api`.

The current backend services deployed to AWS are:

* authentication-service
* customer-service
* product-service
* inventory-service
* order-service
* payment-service
* shipping-service
* api-gateway

The Notification service remains deferred and is not currently part of the deployed platform.

---

## Future Enhancements

Potential future infrastructure work includes:

* ECS service autoscaling
* Load and capacity testing
* Database scaling
* RDS Proxy
* Additional caching infrastructure
* More comprehensive operational dashboards
* Automated deployment pipelines
* Automated infrastructure validation
* Multi-environment Terraform configuration
* Additional disaster recovery and backup automation
* Event-driven infrastructure for asynchronous workflows
* Infrastructure hardening for larger production workloads

The infrastructure can evolve independently as the application platform grows.

---

## Project Status

The infrastructure repository currently provides the AWS foundation for the PC Parts Store platform.

### Implemented

* [x] Terraform-based AWS infrastructure
* [x] VPC networking
* [x] Public/private subnet architecture
* [x] Security groups
* [x] RDS PostgreSQL
* [x] Secrets Manager
* [x] ECR
* [x] ECS/Fargate
* [x] Cloud Map service discovery
* [x] Application Load Balancer
* [x] CloudWatch logging
* [x] S3 frontend hosting
* [x] CloudFront distribution
* [x] IAM roles and policies
* [x] Persistent/application Terraform separation
* [x] AWS deployment of backend services
* [x] AWS deployment of frontend
* [x] End-to-end AWS verification

### Deferred / Future

* [ ] Notification service infrastructure
* [ ] External payment provider integration
* [ ] External shipping provider integration
* [ ] ECS autoscaling
* [ ] Load and capacity testing
* [ ] RDS Proxy
* [ ] Additional caching
* [ ] Advanced operational automation

---

## Related Repositories

### Backend API

`pc-parts-store-api`

Spring Boot microservices implementing the backend platform.

### Frontend

`pc-parts-store-ui`

React/Vite frontend application.

### End-to-End Tests

`pc-parts-store-e2e`

End-to-end test suite for validating the complete platform.

---

## License

This project is provided for learning and portfolio purposes.
