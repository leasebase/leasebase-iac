# DNS and TLS Certificates

This document describes how DNS and TLS certificates are managed for Leasebase via Terraform.

## 1. Domains per environment

- **dev**: `dev.leasebase.io`, `api.dev.leasebase.io`
- **qa**: `qa.leasebase.io`, `api.qa.leasebase.io`
- **uat**: `uat.leasebase.io`, `api.uat.leasebase.io`
- **prod**: `leasebase.io`, `api.leasebase.io`

The web frontend for each environment is served via CloudFront. The API is served via an ALB.

## 2. ACM certificates

We use two categories of ACM certificates:

1. **CloudFront certificates (us-east-1)**
   - Region: `us-east-1` (required by CloudFront).
   - Covers the web domains:
     - `dev.leasebase.io`
     - `qa.leasebase.io`
     - `uat.leasebase.io`
     - `leasebase.io`

2. **Regional certificates for ALB (us-west-2)**
   - Region: `us-west-2` (application region).
   - Covers the API domains:
     - `api.dev.leasebase.io`
     - `api.qa.leasebase.io`
     - `api.uat.leasebase.io`
     - `api.leasebase.io`

Terraform resources under `modules/route53-acm` create and validate these certificates via DNS validation records in Route53.

## 3. Route53 hosted zone patterns

There are two supported patterns for the `leasebase.io` hosted zone:

### 3.1 Hosted zone in the prod account

- The `leasebase-prod` account owns the hosted zone for `leasebase.io`.
- Non-prod environments share the same hosted zone but use distinct records:
  - `dev.leasebase.io`, `api.dev.leasebase.io`
  - `qa.leasebase.io`, `api.qa.leasebase.io`
  - `uat.leasebase.io`, `api.uat.leasebase.io`

In this pattern, Terraform in each environment can either:

- Manage its own subset of records using separate state and proper tagging, or
- Centralize all DNS management in the prod environment configuration.

The `modules/route53-acm/in-account` submodule assumes the hosted zone lives in the same account.

### 3.2 Hosted zone in a shared DNS account

- A separate DNS account owns the `leasebase.io` hosted zone.
- Each application account (`dev`, `qa`, `uat`, `prod`) exposes its ALB and CloudFront endpoints.
- Terraform in the DNS account (or cross-account Terraform using an `aws.dns` provider alias) creates records such as:
  - `dev.leasebase.io` → CloudFront distribution domain (ALIAS).
  - `api.dev.leasebase.io` → ALB DNS name (ALIAS).

The `modules/route53-acm/shared-dns` submodule demonstrates this pattern. It assumes:

- An `aws` provider for the application account.
- An `aws.dns` provider alias for the DNS account.

`envs/prod/main.tf` shows how to wire the providers and choose the shared-DNS submodule.

## 4. CloudFront configuration

The `cloudfront` module provisions a distribution for the web frontend with:

- Origin: ALB DNS name for the `leasebase-web` ECS service.
- Behaviors:
  - Default behavior forwards to the web origin on HTTPS.
- Viewer certificate:
  - ACM certificate in `us-east-1` for the env web domain.
- Aliases:
  - `dev.leasebase.io`, `qa.leasebase.io`, `uat.leasebase.io`, or `leasebase.io` depending on env.

You can add additional behaviors/origins for static assets or API endpoints in the future.

## 5. API endpoints via ALB

The `alb` module provisions:

- An internet-facing ALB in public subnets.
- HTTP (80) → HTTPS (443) redirect.
- HTTPS listener with the env-specific ACM certificate.
- Target groups and listener rules for:
  - `leasebase-api` – path pattern `/api/*` or a dedicated listener.
  - `leasebase-web` – default HTTP(S) traffic for the web app.

Route53 records map `api.<env>.leasebase.io` to the ALB using `A` (ALIAS) records.

## 6. Manual validations

After initial deployment per environment, validate:

1. **Certificates**:
   - In the AWS Console under ACM (both `us-east-1` and `us-west-2`), ensure the certificates are in `ISSUED` status.
   - If stuck in `PENDING_VALIDATION`, check that DNS validation records exist and are correct.

2. **DNS records**:
   - Use `dig` or `nslookup` to verify that `dev.leasebase.io`, `qa.leasebase.io`, etc., resolve to CloudFront or ALB.

3. **HTTPS endpoints**:
   - Visit `https://dev.leasebase.io`, `https://api.dev.leasebase.io`, etc., and confirm valid TLS chains.

Any issues are usually due to misconfigured hosted zone ownership, missing validation records, or ACM not in the correct region.
