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
