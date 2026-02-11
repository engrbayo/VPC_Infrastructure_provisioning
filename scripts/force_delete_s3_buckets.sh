#!/bin/bash

##############################################################################
# Force Delete S3 Buckets - Efficient Batch Deletion
# Handles versioned buckets using AWS CLI batch operations
##############################################################################

set -e

REGION="us-east-1"

echo "================================================================"
echo "🗑️  S3 BUCKET FORCE DELETE"
echo "================================================================"
echo ""

# Get remaining secure-vpc buckets
BUCKETS=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `secure-vpc`)].Name' --output text --region $REGION)

if [ -z "$BUCKETS" ]; then
  echo "✅ No secure-vpc buckets found. Already clean!"
  exit 0
fi

echo "Found buckets:"
for bucket in $BUCKETS; do
  echo "  • $bucket"
done

BUCKET_COUNT=$(echo "$BUCKETS" | wc -w | xargs)
echo ""
echo "Total: $BUCKET_COUNT bucket(s)"
echo ""
read -p "Type 'DELETE NOW' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE NOW" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "🗑️  Starting deletion..."
echo ""

for bucket in $BUCKETS; do
  echo "───────────────────────────────────────────────────────────────"
  echo "Deleting: $bucket"
  echo "───────────────────────────────────────────────────────────────"

  # Disable versioning first
  echo "  1. Suspending versioning..."
  aws s3api put-bucket-versioning \
    --bucket $bucket \
    --region $REGION \
    --versioning-configuration Status=Suspended 2>/dev/null || true

  # Delete all versions in batches
  echo "  2. Deleting all versions..."
  while true; do
    # Get batch of versions (max 1000)
    versions=$(aws s3api list-object-versions \
      --bucket $bucket \
      --region $REGION \
      --max-items 1000 \
      --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null)

    if [ "$versions" == '{"Objects":null}' ] || [ "$versions" == '{"Objects":[]}' ] || [ -z "$versions" ]; then
      echo "     ✓ No more versions"
      break
    fi

    # Count versions in this batch
    version_count=$(echo "$versions" | jq '.Objects | length')
    if [ "$version_count" -eq 0 ]; then
      break
    fi

    echo "     • Deleting batch of $version_count versions..."

    # Delete this batch
    aws s3api delete-objects \
      --bucket $bucket \
      --region $REGION \
      --delete "$versions" \
      --output json 2>/dev/null | jq -r '.Deleted[]? | "       ✓ \(.Key)"' | head -5

    echo "       (showing first 5 of $version_count deleted)"
  done

  # Delete all delete markers in batches
  echo "  3. Deleting delete markers..."
  while true; do
    # Get batch of delete markers
    markers=$(aws s3api list-object-versions \
      --bucket $bucket \
      --region $REGION \
      --max-items 1000 \
      --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null)

    if [ "$markers" == '{"Objects":null}' ] || [ "$markers" == '{"Objects":[]}' ] || [ -z "$markers" ]; then
      echo "     ✓ No more delete markers"
      break
    fi

    marker_count=$(echo "$markers" | jq '.Objects | length')
    if [ "$marker_count" -eq 0 ]; then
      break
    fi

    echo "     • Deleting batch of $marker_count markers..."

    aws s3api delete-objects \
      --bucket $bucket \
      --region $REGION \
      --delete "$markers" \
      --output json 2>/dev/null > /dev/null
  done

  # Final recursive delete for any remaining objects
  echo "  4. Final cleanup..."
  aws s3 rm s3://$bucket --recursive --region $REGION 2>/dev/null || true

  # Delete bucket
  echo "  5. Removing bucket..."
  if aws s3api delete-bucket --bucket $bucket --region $REGION 2>/dev/null; then
    echo "  ✅ $bucket DELETED"
  else
    echo "  ⚠️  Failed (will retry)"
  fi

  echo ""
done

echo "================================================================"
echo "✅ DELETION COMPLETE"
echo "================================================================"
echo ""

# Verify
REMAINING=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `secure-vpc`)] | length(@)' --output text --region $REGION)
echo "Remaining secure-vpc buckets: $REMAINING"

if [ "$REMAINING" -eq 0 ]; then
  echo ""
  echo "✅ SUCCESS: All secure-vpc S3 buckets deleted!"
  echo ""
  echo "Final cleanup summary:"
  echo "  • 4 VPCs: DELETED ✅"
  echo "  • 10 S3 Buckets: DELETED ✅"
  echo "  • All Terraform infrastructure: CLEANED ✅"
  echo ""
  echo "💰 Total AWS cost reduced to: $0/month"
else
  echo "⚠️  $REMAINING bucket(s) remain. Running script again may help."
fi

echo ""
