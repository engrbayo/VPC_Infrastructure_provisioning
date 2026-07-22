#!/bin/bash

##############################################################################
# Global Terraform Infrastructure Scanner
# Scans ALL AWS regions for any Terraform-managed resources
##############################################################################

set -e

echo "================================================================"
echo "🌍 GLOBAL TERRAFORM INFRASTRUCTURE SCANNER"
echo "================================================================"
echo ""
echo "Scanning all AWS regions for Terraform-managed resources..."
echo ""

# Get all AWS regions
REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text 2>/dev/null)

# Global counters
TOTAL_VPCS=0
TOTAL_EC2=0
TOTAL_RDS=0
TOTAL_LAMBDA=0
TOTAL_ELB=0
TOTAL_NAT=0
TOTAL_EIP=0
TOTAL_KMS=0
TOTAL_LOG_GROUPS=0

# Track which regions have resources
declare -a REGIONS_WITH_RESOURCES

echo "Checking $(echo $REGIONS | wc -w | xargs) AWS regions..."
echo ""

for REGION in $REGIONS; do
  REGION_HAS_RESOURCES=0

  # Check VPCs
  VPC_COUNT=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=tag:ManagedBy,Values=Terraform" \
    --query 'Vpcs | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check EC2
  EC2_COUNT=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:ManagedBy,Values=Terraform" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check RDS
  RDS_COUNT=$(aws rds describe-db-instances \
    --region $REGION \
    --query 'DBInstances | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check Lambda
  LAMBDA_COUNT=$(aws lambda list-functions \
    --region $REGION \
    --query 'Functions | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check ELB
  ELB_COUNT=$(aws elbv2 describe-load-balancers \
    --region $REGION \
    --query 'LoadBalancers | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check NAT Gateways
  NAT_COUNT=$(aws ec2 describe-nat-gateways \
    --region $REGION \
    --query 'NatGateways[?State!=`deleted`] | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check Elastic IPs
  EIP_COUNT=$(aws ec2 describe-addresses \
    --region $REGION \
    --query 'Addresses | length(@)' \
    --output text 2>/dev/null || echo 0)

  # Check KMS Keys
  KMS_CUSTOMER=0
  KMS_IDS=$(aws kms list-keys --region $REGION --query 'Keys[].KeyId' --output text 2>/dev/null)
  if [ -n "$KMS_IDS" ]; then
    for key in $KMS_IDS; do
      MANAGER=$(aws kms describe-key --key-id $key --region $REGION --query 'KeyMetadata.KeyManager' --output text 2>/dev/null)
      STATE=$(aws kms describe-key --key-id $key --region $REGION --query 'KeyMetadata.KeyState' --output text 2>/dev/null)
      if [ "$MANAGER" == "CUSTOMER" ] && [ "$STATE" != "PendingDeletion" ]; then
        TAGS=$(aws kms list-resource-tags --key-id $key --region $REGION 2>/dev/null | jq -r '.Tags[]? | select(.TagKey=="ManagedBy") | .TagValue' 2>/dev/null)
        [ "$TAGS" == "Terraform" ] && ((KMS_CUSTOMER++)) || true
      fi
    done
  fi

  # Check CloudWatch Log Groups
  LOG_COUNT=$(aws logs describe-log-groups \
    --region $REGION \
    --query "logGroups[?contains(logGroupName, 'secure-vpc') || contains(logGroupName, 'vpc')] | length(@)" \
    --output text 2>/dev/null || echo 0)

  # Sum up resources in this region
  REGION_TOTAL=$((VPC_COUNT + EC2_COUNT + RDS_COUNT + LAMBDA_COUNT + ELB_COUNT + NAT_COUNT + EIP_COUNT + KMS_CUSTOMER + LOG_COUNT))

  if [ $REGION_TOTAL -gt 0 ]; then
    REGION_HAS_RESOURCES=1
    REGIONS_WITH_RESOURCES+=("$REGION")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📍 $REGION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    [ $VPC_COUNT -gt 0 ] && echo "  • VPCs: $VPC_COUNT"
    [ $EC2_COUNT -gt 0 ] && echo "  • EC2 Instances: $EC2_COUNT"
    [ $RDS_COUNT -gt 0 ] && echo "  • RDS Databases: $RDS_COUNT"
    [ $LAMBDA_COUNT -gt 0 ] && echo "  • Lambda Functions: $LAMBDA_COUNT"
    [ $ELB_COUNT -gt 0 ] && echo "  • Load Balancers: $ELB_COUNT"
    [ $NAT_COUNT -gt 0 ] && echo "  • NAT Gateways: $NAT_COUNT"
    [ $EIP_COUNT -gt 0 ] && echo "  • Elastic IPs: $EIP_COUNT"
    [ $KMS_CUSTOMER -gt 0 ] && echo "  • KMS Keys (Terraform): $KMS_CUSTOMER"
    [ $LOG_COUNT -gt 0 ] && echo "  • CloudWatch Log Groups: $LOG_COUNT"
    echo "  ─────────────────────────────────────"
    echo "  Total: $REGION_TOTAL resource(s)"
    echo ""

    # Add to global counters
    TOTAL_VPCS=$((TOTAL_VPCS + VPC_COUNT))
    TOTAL_EC2=$((TOTAL_EC2 + EC2_COUNT))
    TOTAL_RDS=$((TOTAL_RDS + RDS_COUNT))
    TOTAL_LAMBDA=$((TOTAL_LAMBDA + LAMBDA_COUNT))
    TOTAL_ELB=$((TOTAL_ELB + ELB_COUNT))
    TOTAL_NAT=$((TOTAL_NAT + NAT_COUNT))
    TOTAL_EIP=$((TOTAL_EIP + EIP_COUNT))
    TOTAL_KMS=$((TOTAL_KMS + KMS_CUSTOMER))
    TOTAL_LOG_GROUPS=$((TOTAL_LOG_GROUPS + LOG_COUNT))
  fi
done

# Check S3 buckets (global but region-specific)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 S3 Buckets (Global)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text 2>/dev/null)
S3_TERRAFORM=0
if [ -n "$S3_BUCKETS" ]; then
  for bucket in $S3_BUCKETS; do
    TAGS=$(aws s3api get-bucket-tagging --bucket $bucket 2>/dev/null | jq -r '.TagSet[]? | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      REGION_TAG=$(aws s3api get-bucket-location --bucket $bucket --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
      echo "  • $bucket (Region: $REGION_TAG)"
      ((S3_TERRAFORM++))
    fi
  done
fi
[ $S3_TERRAFORM -eq 0 ] && echo "  ✅ No Terraform-managed S3 buckets found"
echo ""

# Check IAM Roles (global)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "👤 IAM Roles (Global)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IAM_TERRAFORM=0
ALL_ROLES=$(aws iam list-roles --query 'Roles[].RoleName' --output text 2>/dev/null)
if [ -n "$ALL_ROLES" ]; then
  for role in $ALL_ROLES; do
    TAGS=$(aws iam list-role-tags --role-name "$role" 2>/dev/null | jq -r '.Tags[]? | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "  • $role"
      ((IAM_TERRAFORM++))
    fi
  done
fi
[ $IAM_TERRAFORM -eq 0 ] && echo "  ✅ No Terraform-managed IAM roles found"
echo ""

# Summary
echo "================================================================"
echo "📊 GLOBAL SUMMARY"
echo "================================================================"
echo ""
echo "Regions scanned: $(echo $REGIONS | wc -w | xargs)"
echo "Regions with resources: ${#REGIONS_WITH_RESOURCES[@]}"
echo ""
echo "Terraform-managed resources found:"
echo "  • VPCs: $TOTAL_VPCS"
echo "  • EC2 Instances: $TOTAL_EC2"
echo "  • RDS Databases: $TOTAL_RDS"
echo "  • Lambda Functions: $TOTAL_LAMBDA"
echo "  • Load Balancers: $TOTAL_ELB"
echo "  • NAT Gateways: $TOTAL_NAT"
echo "  • Elastic IPs: $TOTAL_EIP"
echo "  • KMS Keys: $TOTAL_KMS"
echo "  • CloudWatch Log Groups: $TOTAL_LOG_GROUPS"
echo "  • S3 Buckets: $S3_TERRAFORM"
echo "  • IAM Roles: $IAM_TERRAFORM"
echo ""

GRAND_TOTAL=$((TOTAL_VPCS + TOTAL_EC2 + TOTAL_RDS + TOTAL_LAMBDA + TOTAL_ELB + TOTAL_NAT + TOTAL_EIP + TOTAL_KMS + TOTAL_LOG_GROUPS + S3_TERRAFORM + IAM_TERRAFORM))

echo "🔢 Total Terraform Resources: $GRAND_TOTAL"
echo ""

if [ $GRAND_TOTAL -eq 0 ]; then
  echo "================================================================"
  echo "✅ ✅ ✅  COMPLETELY CLEAN!  ✅ ✅ ✅"
  echo "================================================================"
  echo ""
  echo "🎉 No Terraform-managed resources found in ANY region!"
  echo "🎉 Your AWS account is completely clean!"
  echo ""
else
  echo "================================================================"
  echo "⚠️  RESOURCES FOUND"
  echo "================================================================"
  echo ""
  echo "Regions with resources:"
  for region in "${REGIONS_WITH_RESOURCES[@]}"; do
    echo "  • $region"
  done
  echo ""
  echo "Would you like to delete these resources?"
fi

echo ""
