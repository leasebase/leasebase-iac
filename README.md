# leasebase-iac

Infrastructure-as-code (Terraform) and CI/CD workflows for deploying Leasebase to a multi-account AWS setup.

- **Accounts/environments**: `leasebase-dev`, `leasebase-qa`, `leasebase-uat`, `leasebase-prod`
- **Primary region**: `us-west-2` (application, RDS, Cognito, ALB, ECS)
- **Edge region**: `us-east-1` (CloudFront + ACM for web certificates)

This repo manages:

- VPC, subnets, NAT, and networking
- ECS cluster + services for `leasebase-api` and `leasebase-web`
- ECR repositories for API and web containers
- Application Load Balancer (ALB) for API + web
- RDS PostgreSQL (private)
- S3 document bucket (private)
- Cognito User Pool, App Client, and hosted domain
- SES identities and basic configuration
- Secrets Manager parameters for credentials and keys
- CloudWatch log groups
- CloudFront distribution for the web application
- Route53 records and ACM certificates
- Remote Terraform state (S3 + DynamoDB per account)
- GitHub Actions CI/CD workflows

See `docs/` for detailed usage.

---

## Deploying to each environment

Detailed CI/CD and account bootstrap docs live in:

- `docs/ACCOUNT_BOOTSTRAP.md` – how to prepare each AWS account (remote state, GitHub OIDC roles, DNS patterns).
- `docs/DEPLOYMENT.md` – how GitHub Actions deploys to `dev`, `qa`, `uat`, `prod`, and how to run Terraform locally.

Below is a concise "how to deploy" summary per environment.

### Prerequisites (all environments)

- Terraform **1.6+** installed.
- AWS CLI v2 installed.
- AWS profiles configured for each account:
  - `leasebase-dev`
  - `leasebase-qa`
  - `leasebase-uat`
  - `leasebase-prod`
- Remote state S3 bucket + DynamoDB table created for each account using `scripts/bootstrap_remote_state.sh` (see `docs/ACCOUNT_BOOTSTRAP.md`).
- Example `*.tfvars.example` files copied to real `*.tfvars` and filled out (non-secret values):

```bash
cd envs/dev
cp dev.tfvars.example dev.tfvars
# edit dev.tfvars
```

Secrets (DB passwords, Stripe keys, JWT secrets, etc.) are **not** stored in tfvars. They are provisioned via Terraform into **Secrets Manager / SSM** and populated out-of-band.

### Dev environment (`envs/dev`, account `leasebase-dev`)

**Local Terraform (optional):**

```bash
cd envs/dev
export AWS_PROFILE=leasebase-dev

# One-time (after remote state is configured)
terraform init

# Plan and apply using your dev.tfvars
terraform plan -var-file="dev.tfvars" -out dev.plan
terraform apply dev.plan
```

**Via GitHub Actions (primary path):**

- Pushing to `main` in this repo triggers the `deploy-dev` workflow (see `docs/DEPLOYMENT.md`).
- The workflow will:
  - Assume `AWS_DEV_ROLE_ARN` via OIDC.
  - Build and push Docker images for `leasebase-api` and `leasebase-web`.
  - Run `terraform init/plan/apply` in `envs/dev`.
  - Run Prisma DB migrations via an ECS one-off task.

### QA environment (`envs/qa`, account `leasebase-qa`)

**Local Terraform:**

```bash
cd envs/qa
export AWS_PROFILE=leasebase-qa

terraform init
terraform plan -var-file="qa.tfvars" -out qa.plan
terraform apply qa.plan
```

**Via GitHub Actions:**

- Use the "Deploy QA" workflow in the **Actions** tab.
- Manually trigger it (`workflow_dispatch`), select the commit/branch to deploy.
- The workflow assumes `AWS_QA_ROLE_ARN`, builds/pushes images, applies Terraform in `envs/qa`, and runs migrations.

### UAT environment (`envs/uat`, account `leasebase-uat`)

**Local Terraform:**

```bash
cd envs/uat
export AWS_PROFILE=leasebase-uat

terraform init
terraform plan -var-file="uat.tfvars" -out uat.plan
terraform apply uat.plan
```

**Via GitHub Actions:**

- Use the "Deploy UAT" workflow.
- Trigger it manually, choose the commit/branch.
- The workflow assumes `AWS_UAT_ROLE_ARN`, builds/pushes images, applies Terraform in `envs/uat`, and runs migrations.

### Prod environment (`envs/prod`, account `leasebase-prod`)

**Local Terraform (with extra care):**

```bash
cd envs/prod
export AWS_PROFILE=leasebase-prod

terraform init
terraform plan -var-file="prod.tfvars" -out prod.plan
# Carefully review the plan before applying
terraform apply prod.plan
```

**Via GitHub Actions (recommended):**

- Use the "Deploy Prod" workflow.
- It is typically protected by GitHub **environments** (manual approvals, reviewers).
- The workflow assumes `AWS_PROD_ROLE_ARN`, builds/pushes images, applies Terraform in `envs/prod`, and runs migrations.

### Notes on rollbacks and troubleshooting

- To rollback infrastructure:
  - Identify a known-good commit.
  - Re-run the relevant deploy workflow pointing at that commit, or check out that commit locally and re-run `terraform apply` with the same tfvars (see `docs/DEPLOYMENT.md` §7).
- To rollback application images:
  - Pick previous image tags in ECR for `leasebase-api` and `leasebase-web`.
  - Pin those tags via tfvars/variables or workflow inputs and redeploy.
- Secret rotation and sensitive changes are covered in `docs/DEPLOYMENT.md` §8.
