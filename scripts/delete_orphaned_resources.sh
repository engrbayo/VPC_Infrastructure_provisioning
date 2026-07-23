#!/bin/bash

##############################################################################
# Delete Orphaned Resources
# Removes CloudWatch Log Groups and IAM Roles from deleted VPCs
##############################################################################

set -e

REGION="us-east-1"
PROJECT="secure-vpc"

echo "================================================================"
echo "🗑️  ORPHANED RESOURCE CLEANUP"
echo "================================================================"
echo ""

# 1. Delete CloudWatch Log Groups
echo "───────────────────────────────────────────────────────────────"
echo "1️⃣  CloudWatch Log Groups"
echo "───────────────────────────────────────────────────────────────"
echo ""

VPC_LOGS=$(aws logs describe-log-groups \
  --region $REGION \
  --query "logGroups[?contains(logGroupName, 'vpc') || contains(logGroupName, '$PROJECT')].logGroupName" \
  --output text 2>/dev/null)

if [ -n "$VPC_LOGS" ]; then
  LOG_COUNT=$(echo "$VPC_LOGS" | wc -w | xargs)
  echo "Found $LOG_COUNT log group(s) to delete:"
  echo "$VPC_LOGS" | tr '\t' '\n' | sed 's/^/  • /'
  echo ""

  read -p "Delete these log groups? Type 'DELETE LOGS' to confirm: " CONFIRM

  if [ "$CONFIRM" == "DELETE LOGS" ]; then
    echo ""
    echo "Deleting log groups..."
    for log_group in $VPC_LOGS; do
      echo "  • Deleting: $log_group"
      if aws logs delete-log-group --log-group-name "$log_group" --region $REGION 2>/dev/null; then
        echo "    ✅ Deleted"
      else
        echo "    ❌ Failed"
      fi
    done
  else
    echo "❌ Skipped log group deletion"
  fi
else
  echo "✅ No log groups to delete"
fi

echo ""

# 2. Delete IAM Roles
echo "───────────────────────────────────────────────────────────────"
echo "2️⃣  IAM Roles"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Find Terraform-managed IAM roles
declare -a TERRAFORM_ROLES
ALL_ROLES=$(aws iam list-roles --query 'Roles[].RoleName' --output text 2>/dev/null)

if [ -n "$ALL_ROLES" ]; then
  for role in $ALL_ROLES; do
    TAGS=$(aws iam list-role-tags --role-name "$role" --output json 2>/dev/null)
    MANAGED_BY=$(echo "$TAGS" | jq -r '.Tags[]? | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    PROJECT_TAG=$(echo "$TAGS" | jq -r '.Tags[]? | select(.Key=="Project") | .Value' 2>/dev/null)

    if [ "$MANAGED_BY" == "Terraform" ] && [ "$PROJECT_TAG" == "$PROJECT" ]; then
      TERRAFORM_ROLES+=("$role")
    fi
  done
fi

if [ ${#TERRAFORM_ROLES[@]} -gt 0 ]; then
  echo "Found ${#TERRAFORM_ROLES[@]} Terraform-managed role(s) to delete:"
  printf '  • %s\n' "${TERRAFORM_ROLES[@]}"
  echo ""

  read -p "Delete these IAM roles? Type 'DELETE ROLES' to confirm: " CONFIRM

  if [ "$CONFIRM" == "DELETE ROLES" ]; then
    echo ""
    echo "Deleting IAM roles..."

    for role in "${TERRAFORM_ROLES[@]}"; do
      echo "  • Processing: $role"

      # Detach managed policies
      ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null)
      if [ -n "$ATTACHED_POLICIES" ]; then
        for policy_arn in $ATTACHED_POLICIES; do
          echo "    - Detaching policy: $(basename $policy_arn)"
          aws iam detach-role-policy --role-name "$role" --policy-arn "$policy_arn" 2>/dev/null || true
        done
      fi

      # Delete inline policies
      INLINE_POLICIES=$(aws iam list-role-policies --role-name "$role" --query 'PolicyNames[]' --output text 2>/dev/null)
      if [ -n "$INLINE_POLICIES" ]; then
        for policy in $INLINE_POLICIES; do
          echo "    - Deleting inline policy: $policy"
          aws iam delete-role-policy --role-name "$role" --policy-name "$policy" 2>/dev/null || true
        done
      fi

      # Delete instance profiles (if any)
      INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role --role-name "$role" --query 'InstanceProfiles[].InstanceProfileName' --output text 2>/dev/null)
      if [ -n "$INSTANCE_PROFILES" ]; then
        for profile in $INSTANCE_PROFILES; do
          echo "    - Removing from instance profile: $profile"
          aws iam remove-role-from-instance-profile --instance-profile-name "$profile" --role-name "$role" 2>/dev/null || true
        done
      fi

      # Delete the role
      echo "    - Deleting role..."
      if aws iam delete-role --role-name "$role" 2>/dev/null; then
        echo "    ✅ Deleted"
      else
        echo "    ❌ Failed"
      fi

      echo ""
    done
  else
    echo "❌ Skipped IAM role deletion"
  fi
else
  echo "✅ No IAM roles to delete"
fi

echo ""
echo "================================================================"
echo "✅ CLEANUP COMPLETE"
echo "================================================================"
echo ""
