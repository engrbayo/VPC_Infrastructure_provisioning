#!/bin/bash

##############################################################################
# KMS Key Scanner & Deletion Tool
# Finds and schedules deletion of Terraform-managed KMS keys
##############################################################################

set -e

REGION="us-east-1"

echo "================================================================"
echo "🔍 KMS KEY SCANNER"
echo "================================================================"
echo ""

# List all KMS keys
echo "Scanning for KMS keys in $REGION..."
KEY_IDS=$(aws kms list-keys --region $REGION --query 'Keys[].KeyId' --output text)

if [ -z "$KEY_IDS" ]; then
  echo "✅ No KMS keys found"
  exit 0
fi

TOTAL_KEYS=$(echo $KEY_IDS | wc -w | xargs)
echo "Found $TOTAL_KEYS KMS key(s)"
echo ""
echo "Filtering for Terraform-managed keys..."
echo ""

TERRAFORM_KEYS=0

# Create temporary file to store Terraform key IDs
TEMP_FILE=$(mktemp)

for key_id in $KEY_IDS; do
  # Get key details
  KEY_INFO=$(aws kms describe-key --key-id $key_id --region $REGION 2>/dev/null)

  # Check if key is AWS-managed (skip those)
  KEY_MANAGER=$(echo "$KEY_INFO" | jq -r '.KeyMetadata.KeyManager')
  KEY_STATE=$(echo "$KEY_INFO" | jq -r '.KeyMetadata.KeyState')

  if [ "$KEY_MANAGER" == "AWS" ]; then
    continue  # Skip AWS-managed keys
  fi

  # Skip if already pending deletion
  if [ "$KEY_STATE" == "PendingDeletion" ]; then
    echo "  ⏳ $key_id (Already pending deletion)"
    continue
  fi

  # Get tags
  TAGS=$(aws kms list-resource-tags --key-id $key_id --region $REGION 2>/dev/null)
  MANAGED_BY=$(echo "$TAGS" | jq -r '.Tags[]? | select(.TagKey=="ManagedBy") | .TagValue' 2>/dev/null)
  PROJECT=$(echo "$TAGS" | jq -r '.Tags[]? | select(.TagKey=="Project") | .TagValue' 2>/dev/null)
  NAME=$(echo "$TAGS" | jq -r '.Tags[]? | select(.TagKey=="Name") | .TagValue' 2>/dev/null)
  ENV=$(echo "$TAGS" | jq -r '.Tags[]? | select(.TagKey=="Environment") | .TagValue' 2>/dev/null)

  # Check if Terraform-managed
  if [ "$MANAGED_BY" == "Terraform" ] || [ "$PROJECT" == "secure-vpc" ]; then
    # Get alias if exists
    ALIAS=$(aws kms list-aliases --key-id $key_id --region $REGION --query 'Aliases[0].AliasName' --output text 2>/dev/null)
    [ "$ALIAS" == "None" ] && ALIAS=""

    echo "  • Key ID: $key_id"
    [ -n "$ALIAS" ] && echo "    Alias: $ALIAS"
    [ -n "$NAME" ] && echo "    Name: $NAME"
    [ -n "$ENV" ] && echo "    Environment: $ENV"
    echo "    State: $KEY_STATE"
    echo ""

    echo "$key_id|$ALIAS|$NAME|$ENV" >> $TEMP_FILE
    ((TERRAFORM_KEYS++)) || true
  fi
done

echo "================================================================"
echo "📊 SUMMARY"
echo "================================================================"
echo ""
echo "Total KMS keys in account: $TOTAL_KEYS"
echo "Terraform-managed keys: $TERRAFORM_KEYS"
echo ""

if [ $TERRAFORM_KEYS -eq 0 ]; then
  echo "✅ No Terraform-managed KMS keys to delete"
  rm -f $TEMP_FILE
  exit 0
fi

echo "⚠️  IMPORTANT: KMS Key Deletion"
echo "  • KMS keys cannot be deleted immediately"
echo "  • AWS enforces a waiting period (7-30 days)"
echo "  • This script will SCHEDULE deletion"
echo "  • Keys will be disabled immediately"
echo "  • Deletion completes after waiting period"
echo ""

read -p "Schedule these $TERRAFORM_KEYS key(s) for deletion? Type 'DELETE KMS' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE KMS" ]; then
  echo ""
  echo "❌ Aborted. No keys were deleted."
  rm -f $TEMP_FILE
  exit 0
fi

echo ""
echo "================================================================"
echo "🗑️  SCHEDULING KEYS FOR DELETION"
echo "================================================================"
echo ""

DELETED_COUNT=0
FAILED_COUNT=0

while IFS='|' read -r key_id alias name env; do
  echo "Processing: $key_id"

  # Delete alias first if exists
  if [ -n "$alias" ] && [ "$alias" != "None" ]; then
    echo "  • Deleting alias: $alias"
    aws kms delete-alias --alias-name "$alias" --region $REGION 2>/dev/null || echo "    ⚠️  Alias deletion failed"
  fi

  # Schedule key deletion (30 day waiting period)
  echo "  • Scheduling key deletion (30 day waiting period)..."
  if aws kms schedule-key-deletion \
    --key-id $key_id \
    --region $REGION \
    --pending-window-in-days 30 \
    --output json 2>/dev/null | jq -r '"    ✓ Deletion scheduled for: " + .DeletionDate'; then
    ((DELETED_COUNT++))
  else
    echo "    ✗ Failed to schedule deletion"
    ((FAILED_COUNT++))
  fi

  echo ""
done < $TEMP_FILE

rm -f $TEMP_FILE

echo "================================================================"
echo "✅ DELETION SCHEDULED"
echo "================================================================"
echo ""
echo "Successfully scheduled: $DELETED_COUNT key(s)"
echo "Failed: $FAILED_COUNT key(s)"
echo ""
echo "💡 Notes:"
echo "  • Keys are now disabled and unusable"
echo "  • Deletion completes automatically after 30 days"
echo "  • You can cancel deletion within 30 days if needed:"
echo "    aws kms cancel-key-deletion --key-id <KEY_ID> --region $REGION"
echo ""
echo "💰 Cost Impact:"
echo "  • KMS keys: \$1/month each"
echo "  • Savings: ~\$$((DELETED_COUNT * 1))/month"
echo ""
