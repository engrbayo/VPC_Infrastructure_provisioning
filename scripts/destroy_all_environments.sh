#!/bin/bash

##############################################################################
# Destroy All Environments Script
# Safely destroys all VPC infrastructures (dev, staging, prod)
##############################################################################

set -e

REGION="us-east-1"
PROJECT="secure-vpc"

echo "================================================================"
echo "🗑️  VPC INFRASTRUCTURE CLEANUP SCRIPT"
echo "================================================================"
echo ""
echo "This script will destroy ALL VPC infrastructures:"
echo "  • Dev environment"
echo "  • Staging environment"
echo "  • Prod environment"
echo ""
echo "⚠️  THIS ACTION IS PERMANENT AND CANNOT BE UNDONE!"
echo ""
echo "================================================================"
echo ""

# Step 1: List existing VPCs
echo "📋 Step 1: Checking for existing VPCs..."
echo ""

VPC_LIST=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Environment`].Value|[0]]' \
  --output text 2>/dev/null)

if [ -z "$VPC_LIST" ]; then
  echo "✅ No VPCs found with project tag '$PROJECT'"
  echo "Nothing to destroy!"
  exit 0
fi

echo "Found the following VPCs:"
echo "$VPC_LIST" | while read vpc_id name env; do
  echo "  • VPC: $vpc_id"
  echo "    Name: $name"
  echo "    Environment: $env"
  echo ""
done

# Count VPCs
VPC_COUNT=$(echo "$VPC_LIST" | wc -l | xargs)
echo "Total VPCs to destroy: $VPC_COUNT"
echo ""

# Step 2: Confirmation
echo "================================================================"
echo "⚠️  FINAL CONFIRMATION"
echo "================================================================"
echo ""
echo "You are about to destroy $VPC_COUNT VPC(s) and ALL associated resources:"
echo ""
echo "  • Subnets (Public, Private, Data)"
echo "  • NAT Gateways and Elastic IPs"
echo "  • Internet Gateway"
echo "  • Route Tables"
echo "  • Security Groups"
echo "  • Network ACLs"
echo "  • VPC Endpoints"
echo "  • VPC Flow Logs (CloudWatch + S3)"
echo "  • IAM Roles"
echo "  • KMS Keys"
echo ""
read -p "Type 'DESTROY ALL' to confirm (case-sensitive): " CONFIRMATION

if [ "$CONFIRMATION" != "DESTROY ALL" ]; then
  echo ""
  echo "❌ Confirmation failed. You entered: '$CONFIRMATION'"
  echo "Required: 'DESTROY ALL'"
  echo ""
  echo "Aborting destruction."
  exit 1
fi

echo ""
echo "✅ Confirmation received. Proceeding with destruction..."
echo ""

# Step 3: Destroy each environment
echo "================================================================"
echo "🗑️  Step 3: Destroying Environments"
echo "================================================================"
echo ""

# Get unique environments
ENVIRONMENTS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'Vpcs[*].Tags[?Key==`Environment`].Value | [] | [0]' \
  --output text | tr '\t' '\n' | sort -u)

for ENV in $ENVIRONMENTS; do
  echo ""
  echo "───────────────────────────────────────────────────────────────"
  echo "🗑️  Destroying: $ENV environment"
  echo "───────────────────────────────────────────────────────────────"
  echo ""

  # Create tfvars for this environment
  cat > destroy_$ENV.auto.tfvars <<EOF
environment = "$ENV"
EOF

  echo "📝 Created destroy_$ENV.auto.tfvars"

  # Initialize Terraform
  echo "🔧 Initializing Terraform..."
  terraform init > /dev/null 2>&1

  # Plan destroy
  echo "📋 Planning destruction..."
  terraform plan -destroy -var-file=destroy_$ENV.auto.tfvars -out=destroy_$ENV.tfplan

  # Show what will be destroyed
  echo ""
  echo "📊 Resources to be destroyed:"
  terraform show -no-color destroy_$ENV.tfplan | grep -A 3 "Plan:"

  # Destroy
  echo ""
  echo "🗑️  Executing terraform destroy for $ENV..."
  terraform destroy -var-file=destroy_$ENV.auto.tfvars -auto-approve

  if [ $? -eq 0 ]; then
    echo ""
    echo "✅ $ENV environment destroyed successfully"

    # Clean up tfvars file
    rm -f destroy_$ENV.auto.tfvars destroy_$ENV.tfplan
  else
    echo ""
    echo "❌ Failed to destroy $ENV environment"
    echo "You may need to manually clean up remaining resources"
  fi

  echo ""
  echo "⏳ Waiting 10 seconds before next environment..."
  sleep 10
done

# Step 4: Verify destruction
echo ""
echo "================================================================"
echo "✅ Step 4: Verification"
echo "================================================================"
echo ""

echo "🔍 Checking for remaining VPCs..."
REMAINING_VPCS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'Vpcs | length(@)' \
  --output text 2>/dev/null)

if [ "$REMAINING_VPCS" -eq 0 ]; then
  echo "✅ All VPCs successfully destroyed!"
else
  echo "⚠️  Warning: $REMAINING_VPCS VPC(s) still exist"
  echo ""
  echo "Remaining VPCs:"
  aws ec2 describe-vpcs \
    --filters "Name=tag:Project,Values=$PROJECT" \
    --region $REGION \
    --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' \
    --output table
  echo ""
  echo "These may be from different Terraform states or require manual cleanup."
fi

# Step 5: Check for orphaned resources
echo ""
echo "🔍 Checking for orphaned resources..."
echo ""

# Check NAT Gateways
NAT_GWS=$(aws ec2 describe-nat-gateways \
  --filter "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'NatGateways[?State!=`deleted`] | length(@)' \
  --output text 2>/dev/null)

if [ "$NAT_GWS" -gt 0 ]; then
  echo "⚠️  $NAT_GWS NAT Gateway(s) still deleting (this is normal)"
fi

# Check Elastic IPs
EIPS=$(aws ec2 describe-addresses \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'Addresses | length(@)' \
  --output text 2>/dev/null)

if [ "$EIPS" -gt 0 ]; then
  echo "⚠️  $EIPS Elastic IP(s) still allocated (may be attached to deleting NAT Gateways)"
fi

# Check S3 Buckets
S3_BUCKETS=$(aws s3 ls --region $REGION | grep "$PROJECT" | wc -l | xargs)

if [ "$S3_BUCKETS" -gt 0 ]; then
  echo "⚠️  $S3_BUCKETS S3 bucket(s) may still exist"
  echo "   Run: aws s3 ls | grep $PROJECT"
fi

# Check CloudWatch Log Groups
LOG_GROUPS=$(aws logs describe-log-groups \
  --log-group-name-prefix "/aws/vpc/$PROJECT" \
  --region $REGION \
  --query 'logGroups | length(@)' \
  --output text 2>/dev/null)

if [ "$LOG_GROUPS" -gt 0 ]; then
  echo "⚠️  $LOG_GROUPS CloudWatch Log Group(s) may still exist"
fi

# Final summary
echo ""
echo "================================================================"
echo "📊 DESTRUCTION SUMMARY"
echo "================================================================"
echo ""
echo "Environments processed: $(echo $ENVIRONMENTS | wc -w | xargs)"
echo "Remaining VPCs: $REMAINING_VPCS"
echo "NAT Gateways deleting: $NAT_GWS"
echo "Elastic IPs: $EIPS"
echo "S3 Buckets: $S3_BUCKETS"
echo "CloudWatch Log Groups: $LOG_GROUPS"
echo ""

if [ "$REMAINING_VPCS" -eq 0 ] && [ "$NAT_GWS" -eq 0 ] && [ "$EIPS" -eq 0 ]; then
  echo "✅ ================================================"
  echo "✅ ALL INFRASTRUCTURE SUCCESSFULLY DESTROYED!"
  echo "✅ ================================================"
  echo ""
  echo "💰 Cost savings: ~$85/month per environment"
  echo ""
  echo "Next steps:"
  echo "  1. Review AWS Cost Explorer in 24 hours to verify"
  echo "  2. Check for any remaining S3 buckets and CloudWatch logs"
  echo "  3. Delete S3 buckets manually if needed:"
  echo "     aws s3 rb s3://bucket-name --force --region $REGION"
else
  echo "⚠️  ================================================"
  echo "⚠️  PARTIAL CLEANUP - Manual review recommended"
  echo "⚠️  ================================================"
  echo ""
  echo "Some resources may still be deleting (NAT Gateways take time)."
  echo "Run this script again in 5 minutes or clean up manually."
  echo ""
  echo "Manual cleanup commands:"
  echo "  • List VPCs: aws ec2 describe-vpcs --region $REGION"
  echo "  • List NATs: aws ec2 describe-nat-gateways --region $REGION"
  echo "  • List EIPs: aws ec2 describe-addresses --region $REGION"
fi

echo ""
echo "🕐 Destruction completed at: $(date)"
echo ""
