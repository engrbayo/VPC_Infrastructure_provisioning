#!/bin/bash

##############################################################################
# Delete S3 Buckets with Versioning Support
# Properly handles buckets with versioning enabled
##############################################################################

set -e

REGION="us-east-1"

echo "================================================================"
echo "🗑️  S3 VERSIONED BUCKET DELETION"
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

echo ""
read -p "Type 'DELETE BUCKETS' to confirm deletion: " CONFIRM

if [ "$CONFIRM" != "DELETE BUCKETS" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "🗑️  Deleting buckets with versioning support..."
echo ""

for bucket in $BUCKETS; do
  echo "───────────────────────────────────────────────────────────────"
  echo "Processing: $bucket"
  echo "───────────────────────────────────────────────────────────────"

  # Check if bucket exists
  if ! aws s3api head-bucket --bucket $bucket --region $REGION 2>/dev/null; then
    echo "  ⚠️  Bucket no longer exists, skipping"
    continue
  fi

  # 1. Delete all object versions and delete markers
  echo "  1. Deleting all object versions and delete markers..."
  aws s3api list-object-versions \
    --bucket $bucket \
    --region $REGION \
    --output json \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' 2>/dev/null | \
    jq -r '.Objects[]? | select(.Key != null) | "--key '\''\(.Key)'\'' --version-id '\''\(.VersionId)'\''"' | \
    xargs -I {} -P 10 sh -c "aws s3api delete-object --bucket $bucket --region $REGION {} 2>/dev/null && echo '     ✓ Deleted version' || true"

  # 2. Delete delete markers
  echo "  2. Removing delete markers..."
  aws s3api list-object-versions \
    --bucket $bucket \
    --region $REGION \
    --output json \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' 2>/dev/null | \
    jq -r '.Objects[]? | select(.Key != null) | "--key '\''\(.Key)'\'' --version-id '\''\(.VersionId)'\''"' | \
    xargs -I {} -P 10 sh -c "aws s3api delete-object --bucket $bucket --region $REGION {} 2>/dev/null && echo '     ✓ Deleted marker' || true"

  # 3. Delete bucket
  echo "  3. Deleting bucket..."
  if aws s3api delete-bucket --bucket $bucket --region $REGION 2>/dev/null; then
    echo "  ✅ $bucket DELETED"
  else
    echo "  ⚠️  Failed to delete $bucket (may need retry)"
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
  echo "✅ All secure-vpc S3 buckets successfully deleted!"
else
  echo "⚠️  $REMAINING bucket(s) still exist. May need another pass."
fi

echo ""
