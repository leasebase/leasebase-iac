#!/bin/bash
# apply-branch-protection.sh
# 
# This script applies branch protection rules to the leasebase-iac repository.
# Requires: GitHub Pro subscription or public repository
# 
# Usage: ./scripts/apply-branch-protection.sh

set -e

REPO="motart/leasebase-iac"
BRANCHES=("main" "develop" "qa")

echo "================================================"
echo "Applying Branch Protection Rules"
echo "Repository: $REPO"
echo "================================================"
echo ""

# Function to apply protection to a branch
apply_protection() {
  local BRANCH=$1
  echo "📋 Applying protection to branch: $BRANCH"
  
  if gh api \
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
    -f required_linear_history=false \
    --silent 2>/dev/null; then
    echo "✅ Protection applied to $BRANCH"
  else
    echo "❌ Failed to apply protection to $BRANCH"
    echo "   Branch may not exist yet or you may need GitHub Pro"
    return 1
  fi
  echo ""
}

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo "❌ Error: GitHub CLI (gh) is not installed"
  echo "   Install it from: https://cli.github.com/"
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo "❌ Error: Not authenticated with GitHub CLI"
  echo "   Run: gh auth login"
  exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# Apply protection to each branch
SUCCESS_COUNT=0
FAIL_COUNT=0

for BRANCH in "${BRANCHES[@]}"; do
  if apply_protection "$BRANCH"; then
    ((SUCCESS_COUNT++))
  else
    ((FAIL_COUNT++))
  fi
done

# Summary
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ Successfully protected: $SUCCESS_COUNT branch(es)"
echo "❌ Failed: $FAIL_COUNT branch(es)"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
  echo "⚠️  Some branches failed protection setup."
  echo "   Common reasons:"
  echo "   - Branch doesn't exist yet (create it first)"
  echo "   - Repository is private and requires GitHub Pro"
  echo "   - Insufficient permissions"
  echo ""
  echo "   To make repository public (if applicable):"
  echo "   gh repo edit $REPO --visibility public"
  exit 1
fi

echo "✅ All branch protection rules applied successfully!"
