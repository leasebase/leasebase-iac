# Branch Protection Configuration

This document describes the branch protection rules that should be applied to the leasebase-iac repository.

**Note**: Branch protection rules require either:
- GitHub Pro/Team/Enterprise subscription for private repositories
- Making the repository public

## Required Branch Protection Rules

The following branches require protection:
- `main` - Production releases
- `develop` - Development integration branch
- `qa` - QA environment branch
- `release/*` - Release branches

## Protection Rules for All Protected Branches

### Required Pull Request Reviews
- **Require pull request reviews before merging**: ✅ Enabled
- **Required approving reviews**: 1 minimum
- **Dismiss stale pull request approvals when new commits are pushed**: ✅ Recommended
- **Require review from Code Owners**: ⚠️ Optional (requires CODEOWNERS file)

### Status Checks
- **Require status checks to pass before merging**: ✅ Enabled (when CI is configured)
  - Terraform fmt check
  - Terraform validate
  - Terraform plan (for review)

### Rules Applied to Administrators
- **Include administrators**: ⚠️ Recommended to disable for emergency fixes, but require PR review for normal workflow

### Restrictions
- **Restrict who can push to matching branches**: 
  - **No one** can push directly to these branches
  - All changes must come through pull requests

### Additional Settings
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled
- **Require linear history**: ✅ Recommended (prevents merge commits if using squash/rebase)
- **Require signed commits**: ⚠️ Optional but recommended for security

## How to Apply These Rules

### Option 1: Upgrade to GitHub Pro (Recommended)
1. Navigate to repository Settings → Billing → Plans and usage
2. Upgrade to GitHub Pro ($4/month per user)
3. Apply branch protection rules via Settings → Branches → Add rule

### Option 2: Make Repository Public
If the repository doesn't contain sensitive information:
```bash
gh repo edit motart/leasebase-iac --visibility public
```

### Option 3: Apply via GitHub CLI (when Pro is available)
Use the provided script below to apply all rules at once.

## Automated Setup Script

Once GitHub Pro is enabled or repository is public, run:

```bash
#!/bin/bash
# apply-branch-protection.sh

REPO="motart/leasebase-iac"
BRANCHES=("main" "develop" "qa" "release/*")

for BRANCH in "${BRANCHES[@]}"; do
  echo "Applying protection to $BRANCH..."
  
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "repos/$REPO/branches/$BRANCH/protection" \
    -f required_status_checks='null' \
    -f enforce_admins=false \
    -f required_pull_request_reviews='{
      "required_approving_review_count": 1,
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": false,
      "require_last_push_approval": false
    }' \
    -f restrictions='null' \
    -f allow_force_pushes=false \
    -f allow_deletions=false \
    -f block_creations=false \
    -f required_linear_history=false
    
  echo "✓ Protection applied to $BRANCH"
done
```

## Alternative: GitHub Actions Enforcement

Until branch protection is available, you can use GitHub Actions to enforce PR requirements:

See `.github/workflows/branch-protection-check.yml` for implementation.

## Verification

After applying branch protection, verify with:
```bash
gh api repos/motart/leasebase-iac/branches/main/protection
```

## Emergency Override

If an emergency fix is needed and you need to bypass protection:
1. Temporarily disable "Include administrators" rule
2. Make the necessary changes
3. Re-enable the rule immediately after
4. Document the override in an incident report

## Related Documents
- [CODEOWNERS](.github/CODEOWNERS) - Define code ownership
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines
- [Pull Request Template](.github/pull_request_template.md) - PR guidelines
