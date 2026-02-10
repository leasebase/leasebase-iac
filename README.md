# LeaseBase Infrastructure

Terraform-based infrastructure-as-code for provisioning the LeaseBase AWS foundation across multiple environments.

## Overview

This repository manages the AWS infrastructure for LeaseBase across 4 isolated environments:

| Environment | VPC CIDR | Description |
|-------------|----------|-------------|
| `dev` | 10.10.0.0/16 | Development environment |
| `qa` | 10.20.0.0/16 | QA/Testing environment |
| `uat` | 10.30.0.0/16 | User Acceptance Testing |
| `prod` | 10.40.0.0/16 | Production environment |

Each environment runs in its **own AWS account** within the same AWS Organization.

## Architecture

### What Gets Created

For each environment, the infrastructure includes:

- **VPC & Networking**
  - VPC with configurable CIDR
  - Public subnets (for ALB, NAT Gateway)
  - Private subnets (for ECS, RDS)
  - Internet Gateway
  - NAT Gateway (optional, recommended for UAT/Prod)
  - Route tables for public and private subnets
  - VPC Flow Logs (optional)

- **Security**
  - ALB security group (ports 80, 443)
  - ECS security group (internal traffic from ALB)
  - RDS security group (PostgreSQL from ECS)
  - VPC Endpoints (S3, DynamoDB gateway; ECR, SSM, CloudWatch Logs interface)

- **IAM**
  - Terraform cross-account access role
  - ECS task execution role
  - ECS task role

### Directory Structure

```
leasebase-iac/
├── bootstrap/           # Remote state backend setup
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/             # Reusable Terraform modules
│   ├── vpc/             # VPC, subnets, NAT, flow logs
│   ├── security/        # Security groups, VPC endpoints
│   └── iam/             # IAM roles for Terraform and ECS
├── environments/        # Environment-specific configurations
│   ├── dev/
│   ├── qa/
│   ├── uat/
│   └── prod/
├── scripts/
│   └── destroy.sh       # Safe destruction script
├── Makefile             # Command shortcuts
└── README.md
```

## Prerequisites

- **Terraform** >= 1.6.0
- **AWS CLI** v2 configured with profiles for each account
- AWS accounts set up in an AWS Organization
- Permissions to create S3 buckets, DynamoDB tables, and IAM roles

### AWS Profile Setup

Configure AWS CLI profiles for each environment's account:

```bash
# ~/.aws/config
[profile leasebase-dev]
region = us-west-2
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-west-2
sso_account_id = 111111111111
sso_role_name = AdministratorAccess

[profile leasebase-qa]
region = us-west-2
sso_account_id = 222222222222
# ... similar config

[profile leasebase-uat]
# ...

[profile leasebase-prod]
# ...
```

## Quick Start

### 1. Bootstrap Remote State (One-time per account)

Before using Terraform, bootstrap the S3 backend in each account:

```bash
# Set your AWS profile
export AWS_PROFILE=leasebase-dev

# Bootstrap the dev account
make bootstrap ENV=dev
```

This creates:
- S3 bucket: `leasebase-tfstate-{account_id}`
- DynamoDB table: `leasebase-terraform-locks`
- IAM role: `leasebase-terraform-access`

### 2. Configure the Environment

```bash
# Copy configuration templates
cd environments/dev
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars

# Edit backend.hcl with your account ID
# Edit terraform.tfvars with your settings
```

### 3. Initialize and Plan

```bash
make init ENV=dev
make plan ENV=dev
```

### 4. Apply Infrastructure

```bash
make apply ENV=dev
```

## Commands Reference

### Environment Commands

| Command | Description |
|---------|-------------|
| `make bootstrap ENV=<env>` | Bootstrap remote state backend |
| `make init ENV=<env>` | Initialize Terraform |
| `make plan ENV=<env>` | Plan infrastructure changes |
| `make apply ENV=<env>` | Apply infrastructure changes |
| `make destroy ENV=<env>` | Destroy infrastructure (with safety prompts) |
| `make output ENV=<env>` | Show Terraform outputs |

### Global Commands

| Command | Description |
|---------|-------------|
| `make validate` | Validate all environments |
| `make fmt` | Format all Terraform code |
| `make fmt-check` | Check formatting (CI mode) |
| `make clean` | Remove .terraform directories |

### Examples

```bash
# Plan dev environment
make plan ENV=dev

# Apply to QA
make apply ENV=qa

# Destroy dev (will prompt for confirmation)
make destroy ENV=dev

# Preview what would be destroyed
make destroy-plan ENV=dev

# Format code
make fmt

# Validate all environments
make validate
```

## Environment Configuration

Each environment has its own configuration files in `environments/<env>/`:

- `backend.hcl` - S3 backend configuration (copy from `backend.hcl.example`)
- `terraform.tfvars` - Variable overrides (copy from `terraform.tfvars.example`)

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `vpc_cidr` | varies | CIDR block for the VPC |
| `enable_nat_gateway` | false (dev/qa), true (uat/prod) | Enable NAT for private subnets |
| `enable_vpc_flow_logs` | false (dev/qa), true (uat/prod) | Enable VPC flow logging |
| `enable_vpc_endpoints` | false (dev/qa), true (prod) | Enable interface VPC endpoints |
| `management_account_id` | required | Account that can assume Terraform role |

### Environment Defaults

| Feature | Dev | QA | UAT | Prod |
|---------|-----|-----|-----|------|
| NAT Gateway | ❌ | ❌ | ✅ | ✅ (multi-AZ) |
| VPC Flow Logs | ❌ | ❌ | ✅ | ✅ |
| VPC Endpoints | ❌ | ❌ | ❌ | ✅ |
| Availability Zones | 2 | 2 | 2 | 3 |

## Destroying Infrastructure

⚠️ **Use extreme caution when destroying infrastructure, especially production.**

### Safe Destruction

The `make destroy` command uses a safety script with multiple confirmation prompts:

```bash
# Destroy dev environment
make destroy ENV=dev
```

The script will:
1. Show the environment and AWS account ID
2. Ask for confirmation (`yes/no`)
3. Verify the last 4 digits of the AWS account ID
4. For production: require typing `destroy production`
5. Show the destruction plan
6. Ask for final confirmation before applying

### Dry Run

Preview what would be destroyed without making changes:

```bash
./scripts/destroy.sh dev --dry-run
```

## Outputs

After applying, the following outputs are available:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `vpc_cidr` | VPC CIDR block |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `alb_security_group_id` | Security group for ALB |
| `ecs_security_group_id` | Security group for ECS tasks |
| `rds_security_group_id` | Security group for RDS |
| `ecs_task_execution_role_arn` | ARN of ECS task execution role |
| `ecs_task_role_arn` | ARN of ECS task role |

View outputs:

```bash
make output ENV=dev
```

## CI/CD Integration

While this repository is designed to run locally, it can also be used in CI/CD pipelines.

### Example GitHub Actions Workflow

```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [main]

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      
      - name: Terraform Format Check
        run: make fmt-check
      
      - name: Terraform Validate
        run: make validate
```

## Troubleshooting

### Backend not configured

```
Error: Backend not configured
```

Run `make init ENV=<env>` after copying `backend.hcl.example` to `backend.hcl`.

### Access Denied

```
Error: Access Denied when accessing S3 bucket
```

Ensure your AWS profile has the correct permissions and the bootstrap has been run.

### State Lock

```
Error: Error acquiring the state lock
```

Another Terraform process may be running. Wait for it to finish or force-unlock:

```bash
cd environments/<env>
terraform force-unlock <LOCK_ID>
```

## Contributing

1. Create a feature branch
2. Make changes
3. Run `make fmt` and `make validate`
4. Submit a pull request

## License

Copyright © LeaseBase. All rights reserved.
