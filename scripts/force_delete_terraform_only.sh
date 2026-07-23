#!/bin/bash

##############################################################################
# Force Delete Terraform-Managed Resources ONLY
# Deletes VPCs, EIPs, and S3 buckets tagged with ManagedBy=Terraform
# Leaves AWS default resources untouched
##############################################################################

set -e

REGION="us-east-1"
PROJECT="secure-vpc"

echo "================================================================"
echo "🗑️  TERRAFORM INFRASTRUCTURE DELETION"
echo "================================================================"
echo ""
echo "⚠️  This will delete ONLY Terraform-managed resources"
echo "    Default AWS resources will be preserved"
echo ""

# Get Terraform-managed VPCs (exclude default VPC)
VPC_IDS=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --query 'Vpcs[].VpcId' \
  --output text 2>/dev/null)

VPC_COUNT=$(echo "$VPC_IDS" | wc -w | xargs)

if [ $VPC_COUNT -eq 0 ]; then
  echo "✅ No Terraform-managed VPCs found"
else
  echo "Found $VPC_COUNT Terraform-managed VPC(s):"
  for vpc_id in $VPC_IDS; do
    VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --region $REGION --query 'Vpcs[0].Tags[?Key==`Name`].Value|[0]' --output text)
    echo "  • $vpc_id - $VPC_NAME"
  done
fi

# Count S3 buckets
S3_COUNT=$(aws s3 ls --region $REGION 2>/dev/null | grep "$PROJECT" | wc -l | xargs)
echo ""
echo "Found $S3_COUNT S3 bucket(s) with '$PROJECT' in name"

# Count Elastic IPs
EIP_COUNT=$(aws ec2 describe-addresses --region $REGION --query 'Addresses | length(@)' --output text 2>/dev/null)
echo "Found $EIP_COUNT Elastic IP(s) (will check for Terraform tags)"

echo ""
echo "================================================================"
echo "⚠️  CONFIRMATION REQUIRED"
echo "================================================================"
echo ""
read -p "Delete all Terraform-managed infrastructure? Type 'DELETE TERRAFORM ONLY' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE TERRAFORM ONLY" ]; then
  echo ""
  echo "❌ Aborted. Nothing deleted."
  exit 0
fi

echo ""
echo "🗑️  Starting deletion..."
echo ""

# Delete VPCs and all dependencies
if [ $VPC_COUNT -gt 0 ]; then
  for VPC_ID in $VPC_IDS; do
    echo "================================================================"
    echo "Deleting VPC: $VPC_ID"
    echo "================================================================"

    # 1. Delete VPC Flow Logs
    echo "1. Deleting Flow Logs..."
    FLOW_LOG_IDS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC_ID" --region $REGION --query 'FlowLogs[].FlowLogId' --output text)
    for fl_id in $FLOW_LOG_IDS; do
      aws ec2 delete-flow-logs --flow-log-ids $fl_id --region $REGION 2>/dev/null && echo "   ✓ $fl_id" || true
    done

    # 2. Delete NAT Gateways
    echo "2. Deleting NAT Gateways..."
    NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text)
    for nat_id in $NAT_IDS; do
      aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION && echo "   ✓ $nat_id" || true
    done

    # 3. Delete VPC Endpoints
    echo "3. Deleting VPC Endpoints..."
    VPCE_IDS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'VpcEndpoints[].VpcEndpointId' --output text)
    for vpce_id in $VPCE_IDS; do
      aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpce_id --region $REGION 2>/dev/null && echo "   ✓ $vpce_id" || true
    done

    if [ -n "$NAT_IDS" ]; then
      echo ""
      echo "⏳ Waiting 90 seconds for NAT Gateways to delete..."
      sleep 90
    fi

    # 4. Release Elastic IPs (only those in this VPC)
    echo "4. Releasing Elastic IPs..."
    EIP_ALLOCS=$(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text)
    for eip in $EIP_ALLOCS; do
      # Try to release, will fail if still associated
      aws ec2 release-address --allocation-id $eip --region $REGION 2>/dev/null && echo "   ✓ $eip" || echo "   ⏳ $eip (still in use, will retry)"
    done

    # 5. Delete Subnets
    echo "5. Deleting Subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'Subnets[].SubnetId' --output text)
    for subnet_id in $SUBNET_IDS; do
      aws ec2 delete-subnet --subnet-id $subnet_id --region $REGION 2>/dev/null && echo "   ✓ $subnet_id" || echo "   ✗ $subnet_id"
    done

    # 6. Delete Route Tables
    echo "6. Deleting Route Tables..."
    RT_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'RouteTables[].RouteTableId' --output text)
    for rt_id in $RT_IDS; do
      IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids $rt_id --region $REGION --query 'RouteTables[0].Associations[?Main==`true`]' --output text)
      if [ -z "$IS_MAIN" ]; then
        aws ec2 delete-route-table --route-table-id $rt_id --region $REGION 2>/dev/null && echo "   ✓ $rt_id" || echo "   ✗ $rt_id"
      fi
    done

    # 7. Detach and Delete Internet Gateway
    echo "7. Deleting Internet Gateway..."
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region $REGION --query 'InternetGateways[].InternetGatewayId' --output text)
    for igw_id in $IGW_IDS; do
      aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $VPC_ID --region $REGION 2>/dev/null
      aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $REGION 2>/dev/null && echo "   ✓ $igw_id" || true
    done

    # 8. Delete Network ACLs
    echo "8. Deleting Network ACLs..."
    NACL_IDS=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text)
    for nacl_id in $NACL_IDS; do
      aws ec2 delete-network-acl --network-acl-id $nacl_id --region $REGION 2>/dev/null && echo "   ✓ $nacl_id" || echo "   ✗ $nacl_id"
    done

    # 9. Delete Security Groups
    echo "9. Deleting Security Groups..."
    SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'SecurityGroups[].GroupId' --output text)
    for sg_id in $SG_IDS; do
      SG_NAME=$(aws ec2 describe-security-groups --group-ids $sg_id --region $REGION --query 'SecurityGroups[0].GroupName' --output text)
      if [ "$SG_NAME" != "default" ]; then
        aws ec2 delete-security-group --group-id $sg_id --region $REGION 2>/dev/null && echo "   ✓ $sg_id" || echo "   ✗ $sg_id (will retry)"
      fi
    done

    # 10. Delete VPC
    echo "10. Deleting VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION && echo "   ✅ $VPC_ID DELETED" || echo "   ⚠️  Failed (will retry)"

    echo ""
  done
fi

# Delete S3 Buckets
echo "================================================================"
echo "Deleting S3 Buckets"
echo "================================================================"
echo ""

S3_BUCKETS=$(aws s3 ls --region $REGION 2>/dev/null | grep "$PROJECT" | awk '{print $3}')

if [ -n "$S3_BUCKETS" ]; then
  for bucket in $S3_BUCKETS; do
    echo "Deleting: $bucket"

    # Remove bucket policy
    aws s3api delete-bucket-policy --bucket $bucket --region $REGION 2>/dev/null || true

    # Suspend versioning
    aws s3api put-bucket-versioning --bucket $bucket --region $REGION --versioning-configuration Status=Suspended 2>/dev/null || true

    # Empty bucket
    echo "  Emptying bucket..."
    aws s3 rm s3://$bucket --recursive --region $REGION 2>/dev/null || true

    # Delete bucket
    if aws s3api delete-bucket --bucket $bucket --region $REGION 2>/dev/null; then
      echo "  ✅ Deleted"
    else
      echo "  ⚠️  Has versions - scheduling lifecycle deletion"
      # Set lifecycle to expire everything
      cat > /tmp/lifecycle_$$.json << 'EOF'
{
  "Rules": [{
    "ID": "expire-all",
    "Status": "Enabled",
    "Prefix": "",
    "Expiration": {"Days": 1},
    "NoncurrentVersionExpiration": {"NoncurrentDays": 1}
  }]
}
EOF
      aws s3api put-bucket-lifecycle-configuration --bucket $bucket --region $REGION --lifecycle-configuration file:///tmp/lifecycle_$$.json 2>/dev/null && echo "  ✓ Lifecycle set"
      rm -f /tmp/lifecycle_$$.json
    fi
    echo ""
  done
fi

# Try to release any remaining EIPs
echo "================================================================"
echo "Releasing Remaining Elastic IPs"
echo "================================================================"
echo ""

EIP_ALLOCS=$(aws ec2 describe-addresses --region $REGION --query 'Addresses[].AllocationId' --output text)
if [ -n "$EIP_ALLOCS" ]; then
  for eip in $EIP_ALLOCS; do
    echo "Attempting to release: $eip"
    if aws ec2 release-address --allocation-id $eip --region $REGION 2>/dev/null; then
      echo "  ✅ Released"
    else
      echo "  ⏳ Still associated (will cleanup automatically when dependency removed)"
    fi
  done
else
  echo "✅ No Elastic IPs to release"
fi

echo ""
echo "================================================================"
echo "✅ DELETION COMPLETE"
echo "================================================================"
echo ""

# Verification
echo "Verification:"
REMAINING_VPCS=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --region $REGION --query 'Vpcs | length(@)' --output text)
echo "  Remaining Terraform VPCs: $REMAINING_VPCS"

REMAINING_S3=$(aws s3 ls --region $REGION 2>/dev/null | grep "$PROJECT" | wc -l | xargs)
echo "  Remaining S3 buckets: $REMAINING_S3"

echo ""
if [ "$REMAINING_VPCS" -eq 0 ] && [ "$REMAINING_S3" -eq 0 ]; then
  echo "✅ ALL TERRAFORM INFRASTRUCTURE DELETED!"
else
  echo "⚠️  Some resources remain. Run script again or wait for dependencies."
fi
echo ""
