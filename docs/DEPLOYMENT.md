# Deployment Guide

This document explains how to deploy Leasebase to each environment using `leasebase-iac` and GitHub Actions.

Environments:

- `dev` → account `leasebase-dev` → domains `dev.leasebase.io`, `api.dev.leasebase.io`
- `qa` → account `leasebase-qa` → domains `qa.leasebase.io`, `api.qa.leasebase.io`
- `uat` → account `leasebase-uat` → domains `uat.leasebase.io`, `api.uat.leasebase.io`
- `prod` → account `leasebase-prod` → domains `leasebase.io`, `api.leasebase.io`

## 1. CI/CD overview

CI/CD is driven by GitHub Actions workflows in `.github/workflows`:

- `quality.yml` – Runs Terraform formatting, validation, and plan on pull requests.
- `deploy-dev.yml` – Automatically deploys to **dev** on push/merge to `main`.
- `deploy-qa.yml` – Manual deployment to **qa** via `workflow_dispatch`.
- `deploy-uat.yml` – Manual deployment to **uat** via `workflow_dispatch`.
- `deploy-prod.yml` – Manual deployment to **prod** via `workflow_dispatch`.

Each deploy workflow performs:

1. Assumes an AWS IAM role in the target account via GitHub OIDC.
2. Builds Docker images for `leasebase-api` and `leasebase-web` from their respective repos.
3. Pushes images to the ECR repositories provisioned by Terraform.
4. Runs `terraform init/plan/apply` in `envs/<env>`.
5. Triggers Prisma DB migrations using an ECS one-off task and waits for completion.

## 2. Local deployment (optional)

While CI/CD is the primary workflow, you can run Terraform locally for troubleshooting or manual changes.

Example for `dev`:

```bash path=null start=null
cd envs/dev

# Ensure backend is configured in backend.tf and remote state bucket/table exist
terraform init
terraform plan -var-file="dev.tfvars" -out dev.plan
terraform apply dev.plan
```

Use the corresponding folder and tfvars file for `qa`, `uat`, and `prod`.

## 3. Required GitHub secrets and variables

In the `motart/leasebase-iac` GitHub repo, configure:

Repository **variables** (non-sensitive):

- `AWS_DEV_ROLE_ARN` – IAM role ARN for dev account.
- `AWS_QA_ROLE_ARN` – IAM role ARN for qa account.
- `AWS_UAT_ROLE_ARN` – IAM role ARN for uat account.
- `AWS_PROD_ROLE_ARN` – IAM role ARN for prod account.
- Optional: `AWS_REGION` (defaults to `us-west-2`).

Repository **secrets**:

- `GH_PAT` (optional) – Personal access token if you need to checkout private repos across organisations; if all repos are in the same org and Actions has access, you may not need this.

Container image builds use `actions/checkout` with the `repository` parameter to pull:

- `motart/leasebase-api`
- `motart/leasebase-web`

## 4. Environment configuration (`tfvars`)

Each environment has an example tfvars file under `envs/<env>/<env>.tfvars.example`.

Copy it to a real tfvars file and fill in non-secret values:

```bash path=null start=null
cd envs/dev
cp dev.tfvars.example dev.tfvars
# edit dev.tfvars
```

Secrets (DB password, Stripe keys, JWT secrets, etc.) are **not** stored in tfvars. Instead, Terraform provisions AWS Secrets Manager / SSM parameters, and CI/workflows or manual processes should populate them.

## 5. Running deployments via GitHub Actions

### 5.1 Dev (automatic)

- Pushing to `main` triggers `deploy-dev.yml`.
- The workflow will:
  - Assume the dev role via OIDC.
  - Build and push images to the dev ECR repos.
  - Apply Terraform in `envs/dev`.
  - Trigger the Prisma migration task on the dev ECS cluster.

### 5.2 QA, UAT, Prod (manual approvals)

These workflows are triggered manually:

1. Go to the **Actions** tab in GitHub.
2. Select `Deploy QA`, `Deploy UAT`, or `Deploy Prod`.
3. Click **Run workflow**, pick the branch/commit, and supply any required inputs (e.g., image tags) if configured.
4. The workflow will:
   - Assume the appropriate role.
   - Build and push images to the environment's ECR.
   - Apply Terraform for that env.
   - Run the Prisma migration task.

`deploy-qa.yml`, `deploy-uat.yml`, and `deploy-prod.yml` are configured with `environment` protection in GitHub so you can require manual approvals.

## 6. Prisma migrations via ECS one-off task

Each environment defines an ECS Task Definition for database migrations (e.g., `leasebase-api-migrate`). The deploy workflows:

1. Use Terraform outputs to capture the migration task definition ARN and cluster name.
2. Call `aws ecs run-task` with `launchType FARGATE` and appropriate subnets and security groups.
3. Poll task status until it reaches `STOPPED`.
4. Check the exit code and fail the workflow if non-zero.

This ensures DB migrations are performed **in the same container image** as the running API service.

## 7. Rollback strategy

### Infrastructure rollback

If a Terraform change breaks infrastructure:

1. Identify the last known-good Git commit in `leasebase-iac`.
2. Re-run the relevant deploy workflow (`dev`, `qa`, `uat`, `prod`) pointing at that commit, or locally:

```bash path=null start=null
cd envs/prod
git checkout <known-good-commit>
terraform init
terraform apply -var-file="prod.tfvars"
```

Because Terraform is declarative, applying an older configuration will roll back resources to the previous state where possible.

### Application rollback

If a bad application image is deployed:

1. Find the previous good image tag in ECR (for both `leasebase-api` and `leasebase-web`).
2. Set those tags as workflow inputs (if configured) or temporarily pin them in env tfvars/variables.
3. Re-run the deploy workflow to update ECS services to the known-good images.

### Database migrations

- Aim for **backwards-compatible** migrations whenever possible.
- In cases where a destructive migration is required:
  - Take an RDS snapshot beforehand.
  - Use Prisma migration previews to validate SQL.
  - Have a runbook for restore-from-snapshot in case of failure.

## 8. Secret rotation

Secrets (DB passwords, Stripe keys, JWT secrets) are stored in AWS Secrets Manager or SSM parameter store.

Rotation steps:

1. **Create new value** in Secrets Manager/SSM for the relevant key.
2. **Update application configuration** (if necessary) to support multiple keys during the transition (e.g., old + new JWT signing keys).
3. **Redeploy** the environment so ECS tasks pick up the new secrets via task definition environment variables.
4. **Clean up old secrets** once you are confident the new ones are working.

The exact secret names/paths are defined in `envs/<env>/variables.tf` and used by ECS task definitions.
