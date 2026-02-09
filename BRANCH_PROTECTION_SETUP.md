# Branch Protection Setup for leasebase-iac

## Current Status: ⚠️ Not Active

Branch protection rules are **not currently active** because:
- Repository is **private**
- GitHub Free tier doesn't support branch protection for private repositories

## Required Action

Choose one of the following options to enable branch protection:

### Option 1: Upgrade to GitHub Pro (Recommended)
**Cost**: $4/month per user

1. Go to https://github.com/settings/billing/plans
2. Upgrade to GitHub Pro
3. Run the setup script:
   ```bash
   cd /Users/rachid/workspace/leasebase_all/leasebase-iac
   ./scripts/apply-branch-protection.sh
   ```

### Option 2: Make Repository Public
⚠️ **Only do this if the repository doesn't contain sensitive information**

```bash
gh repo edit motart/leasebase-iac --visibility public
./scripts/apply-branch-protection.sh
```

## What Will Be Protected

Once activated, the following branches will be protected:
- ✅ **main** - Production releases
- ✅ **develop** - Development integration (will be protected when created)
- ✅ **qa** - QA environment (will be protected when created)
- ✅ **release/*** - Release branches (pattern-based protection)

## Protection Rules Applied

- ❌ **No direct pushes** - All changes must go through pull requests
- ✅ **Require 1 reviewer** - At least one approval needed before merge
- ❌ **No force pushes** - History cannot be rewritten
- ❌ **No deletions** - Protected branches cannot be deleted
- ✅ **Dismiss stale reviews** - Re-review required after new commits

## Manual Setup (Alternative)

If you prefer to set up via GitHub UI:

1. Go to: https://github.com/motart/leasebase-iac/settings/branches
2. Click "Add rule" for each branch (main, develop, qa)
3. Configure:
   - Branch name pattern: `main` (or `develop`, `qa`)
   - ✅ Require a pull request before merging
   - ✅ Require approvals: 1
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ❌ Allow force pushes
   - ❌ Allow deletions
4. Click "Create" or "Save changes"

## Verification

After setup, verify protection is active:

```bash
gh api repos/motart/leasebase-iac/branches/main/protection
```

Expected output should show protection settings (not a 404 error).

## Workflow Impact

Once protection is active:

### ✅ Allowed
- Creating feature branches from protected branches
- Opening pull requests to protected branches
- Approving pull requests (if you're a reviewer)
- Merging approved pull requests

### ❌ Not Allowed
- Direct push to main, develop, or qa branches
- Force pushing to protected branches
- Deleting protected branches
- Merging without required approvals

## Documentation

Full details in:
- [.github/BRANCH_PROTECTION.md](.github/BRANCH_PROTECTION.md)
- Setup script: [scripts/apply-branch-protection.sh](scripts/apply-branch-protection.sh)
