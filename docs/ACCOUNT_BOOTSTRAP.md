# Account Bootstrap

This document describes how to bootstrap each AWS account for use with `leasebase-iac`.

Accounts (one per environment):

- `leasebase-dev`
- `leasebase-qa`
- `leasebase-uat`
- `leasebase-prod`

## 1. Prerequisites

- Terraform 1.6+ installed.
- AWS CLI v2 installed and configured with profiles that can assume admin in each account.
- A Route53 hosted zone for `leasebase.io` already exists **either**:
  - In the `leasebase-prod` account, **or**
  - In a separate shared DNS account.

You also need a GitHub organisation/user `motart` with repositories:

- `motart/leasebase-api`
- `motart/leasebase-web`
- `motart/leasebase-mobile` (not directly used here but part of the ecosystem)
- `motart/leasebase-iac` (this repo)

## 2. Remote state backend per account

Terraform state is stored **per account** in an S3 bucket with a DynamoDB table for state locking.

For each account, run (from this repo root):

```bash path=null start=null
scripts/bootstrap_remote_state.sh \
  --profile leasebase-dev \
  --region us-west-2 \
  --env dev \
  --bucket-prefix leasebase-tfstate
```

Repeat for `qa`, `uat`, and `prod` using the appropriate `--profile` and `--env` values.

This script will:

- Create (or reuse) an S3 bucket named like `leasebase-tfstate-<env>-<account-id>`.
- Enable bucket versioning and basic encryption.
- Create a DynamoDB table `terraform-locks-<env>` for state locking.

Record the bucket name and table name and map them into each env's `backend.tf` (or via `TF_VAR_*` if you template it).

## 3. GitHub OIDC provider and IAM roles

Each account needs a GitHub OIDC identity provider and at least one IAM role that GitHub Actions can assume.

### 3.1 Terraform-driven bootstrap

Under `modules/gha_oidc`, this repo provides Terraform to create:

- An AWS IAM OIDC provider for GitHub (`token.actions.githubusercontent.com`).
- One or more IAM roles for CI/CD with trust policies bound to specific GitHub repos.

For each account, you can run Terraform in a temporary bootstrap workspace using that module, or you can integrate the module directly into `envs/<env>/main.tf` and apply it after remote state is available.

### 3.2 Example trust policy JSON

The core trust relationship for GitHub OIDC looks like this (see module for the authoritative version):

```json path=null start=null
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:motart/leasebase-iac:*",
            "repo:motart/leasebase-api:*",
            "repo:motart/leasebase-web:*"
          ]
        }
      }
    }
  ]
}
```

## 4. Route53 and hosted zone ownership patterns

There are **two supported patterns** for the `leasebase.io` hosted zone:

1. **Zone lives in the prod account.**
   - All DNS records for `*.leasebase.io` are managed from `leasebase-prod`.
   - Non-prod envs use subdomains (`dev.leasebase.io`, `qa.leasebase.io`, `uat.leasebase.io`) with records created in the same zone but logically grouped by environment.

2. **Zone lives in a shared DNS account.**
   - `leasebase-prod` and the non-prod accounts delegate ownership of specific subdomains via NS records or manage them centrally in the DNS account.
   - Terraform in `leasebase-iac` assumes a separate AWS role in the DNS account when operating on Route53 records.

Both patterns are implemented under `modules/route53-acm` via submodules:

- `modules/route53-acm/in-account` – for when the zone is in the same account.
- `modules/route53-acm/shared-dns` – for when DNS is in a dedicated account.

`envs/prod/main.tf` shows how to use the shared DNS submodule; non-prod envs default to in-account.

## 5. Minimum manual steps per account

Per account you must ensure:

1. Admin credentials (profile) exist locally.
2. Remote state S3 bucket + DynamoDB table are created via `scripts/bootstrap_remote_state.sh`.
3. GitHub OIDC provider + IAM role are created (either with the `gha_oidc` module or manually).
4. For `prod`, confirm whether DNS is hosted in-prod or in a shared account and adjust the `route53-acm` module usage accordingly.

Once these steps are complete, you can run Terraform for each environment as described in `docs/DEPLOYMENT.md`.
