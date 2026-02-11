# LeaseBase Infrastructure as Code

Terraform-based infrastructure for deploying the LeaseBase application to AWS.

## Architecture

```
                                    ┌─────────────────┐
                                    │   CloudFront    │ (optional)
                                    │  Static Assets  │
                                    └────────┬────────┘
                                             │
┌──────────────────────────────────────────────────────────────────────────┐
│                              Public Subnets                              │
│  ┌─────────────┐    ┌─────────────────────────────────────────────────┐  │
│  │     ALB     │───▶│  ECS Fargate Cluster                            │  │
│  │  (HTTP/S)   │    │  ┌─────────────┐  ┌─────────────┐               │  │
│  └─────────────┘    │  │  API Service │  │ Web Service │               │  │
│        │            │  │  (backend)   │  │ (frontend)  │               │  │
│        │            │  └──────┬──────┘  └─────────────┘               │  │
│        │            └─────────┼───────────────────────────────────────┘  │
└────────┼──────────────────────┼──────────────────────────────────────────┘
         │                      │
┌────────┼──────────────────────┼──────────────────────────────────────────┐
│        │             Private Subnets                                     │
│        │                      │                                          │
│        │            ┌─────────▼─────────┐                                │
│        │            │   RDS PostgreSQL  │                                │
│        │            └───────────────────┘                                │
└────────┼─────────────────────────────────────────────────────────────────┘
         │
    ┌────▼────┐
    │   ECR   │
    │  Repos  │
    └─────────┘
```

## Directory Structure

```
leasebase-iac/
├── envs/
│   └── common/              # Shared module for all environments
│       ├── main.tf          # VPC, subnets, NAT gateway
│       ├── ecr.tf           # ECR repositories (api, web)
│       ├── rds.tf           # PostgreSQL database
│       ├── alb.tf           # Application Load Balancer
│       ├── ecs-api.tf       # ECS cluster + API service
│       ├── ecs-web.tf       # Web frontend service
│       ├── iam.tf           # ECS task roles
│       ├── security-groups.tf
│       ├── storage.tf       # S3 + CloudFront
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/                 # Dev environment root
│   ├── qa/                  # QA environment root
│   ├── uat/                 # UAT environment root
│   └── prod/                # Production environment root
├── modules/                 # Legacy standalone modules
└── bootstrap/               # Remote state bootstrap
```

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI v2 configured with appropriate profiles
- Access to target AWS accounts

## Quick Start

### 1. Initialize Backend (First Time Only)

```bash
# Create S3 bucket and DynamoDB table for state
./scripts/bootstrap_remote_state.sh \
  --profile leasebase-dev \
  --region us-west-2 \
  --env dev \
  --bucket-prefix leasebase-tfstate
```

### 2. Configure Backend

Create `environments/dev/backend.hcl`:

```hcl
bucket         = "leasebase-tfstate-dev-ACCOUNT_ID"
key            = "dev/terraform.tfstate"
region         = "us-west-2"
dynamodb_table = "leasebase-tfstate-lock-dev"
encrypt        = true
```

### 3. Create Variables File

Create `environments/dev/dev.tfvars`:

```hcl
db_password = "your-secure-password"

# Optional overrides
# api_task_cpu    = 512
# api_task_memory = 1024
# api_desired_count = 2
```

### 4. Deploy

```bash
cd environments/dev

# Initialize
terraform init -backend-config=backend.hcl

# Plan
terraform plan -var-file=dev.tfvars -out=dev.plan

# Apply
terraform apply dev.plan
```

## Environments

| Environment | VPC CIDR | Purpose |
|-------------|----------|---------|
| dev | 10.10.0.0/16 | Development |
| qa | 10.20.0.0/16 | QA testing |
| uat | 10.30.0.0/16 | User acceptance |
| prod | 10.40.0.0/16 | Production |

## Key Resources Created

### Per Environment

- **VPC** with public/private subnets across 2 AZs
- **ECR Repositories**: `leasebase-{env}-api`, `leasebase-{env}-web`
- **RDS PostgreSQL** instance (private subnet)
- **Application Load Balancer** with path-based routing:
  - `/api/*`, `/docs*`, `/healthz`, `/readyz` → API service
  - `/*` → Web service
- **ECS Fargate Cluster** with API and Web services
- **S3 Bucket** for document storage
- **CloudWatch Log Groups** for ECS tasks

## CI/CD Integration

### Deploying Backend (leasebase-api)

```bash
# Build and push to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com
docker build -t leasebase-dev-api .
docker tag leasebase-dev-api:latest ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/leasebase-dev-api:latest
docker push ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/leasebase-dev-api:latest

# Force new deployment
aws ecs update-service --cluster leasebase-dev-cluster --service leasebase-dev-api --force-new-deployment
```

### Deploying Frontend (leasebase-web)

```bash
# Build and push to ECR
docker build -t leasebase-dev-web .
docker tag leasebase-dev-web:latest ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/leasebase-dev-web:latest
docker push ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/leasebase-dev-web:latest

# Force new deployment
aws ecs update-service --cluster leasebase-dev-cluster --service leasebase-dev-web --force-new-deployment
```

## Variables Reference

### Required

| Variable | Description |
|----------|-------------|
| `db_password` | RDS master password |

### Optional (with defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `vpc_cidr` | 10.10.0.0/16 | VPC CIDR block |
| `az_count` | 2 | Number of availability zones |
| `enable_nat_gateway` | false | Enable NAT for private subnets |
| `db_instance_class` | db.t3.micro | RDS instance type |
| `api_task_cpu` | 256 | API task CPU units |
| `api_task_memory` | 512 | API task memory (MB) |
| `api_desired_count` | 1 | Number of API tasks |
| `web_task_cpu` | 256 | Web task CPU units |
| `web_task_memory` | 512 | Web task memory (MB) |
| `web_desired_count` | 1 | Number of web tasks |
| `acm_certificate_arn` | "" | ACM cert for HTTPS |

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | ALB DNS name for accessing the app |
| `ecr_api_repository_url` | ECR URL for API images |
| `ecr_web_repository_url` | ECR URL for web images |
| `rds_endpoint` | Database connection endpoint |
| `ecs_cluster_name` | ECS cluster name |

## Common Commands

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate without backend
cd environments/dev
terraform init -backend=false
terraform validate

# Destroy environment (use with caution)
terraform destroy -var-file=dev.tfvars
```

## Cost Optimization (Dev/QA)

The dev configuration uses cost-effective settings:
- `db.t3.micro` RDS instance
- No NAT Gateway (ECS in public subnets with public IPs)
- Single NAT Gateway option when enabled
- Minimal ECS task sizes (256 CPU, 512 MB)
- 7-day log retention

For production, consider:
- Larger RDS instance with Multi-AZ
- NAT Gateway for private ECS tasks
- Higher task CPU/memory
- Longer log retention
- Deletion protection enabled
