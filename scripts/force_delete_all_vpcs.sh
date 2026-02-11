#!/bin/bash

##############################################################################
# Force Delete All VPCs - Pure AWS CLI (No Terraform)
# Deletes VPCs directly using AWS API, ignoring Terraform state
##############################################################################

set -e

REGION="us-east-1"
PROJECT="secure-vpc"

echo "================================================================"
echo "🗑️  FORCE DELETE ALL VPCs (AWS CLI Direct)"
echo "================================================================"
echo ""

# Get all VPCs
VPC_IDS=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT" \
  --region $REGION \
  --query 'Vpcs[*].VpcId' \
  --output text)

if [ -z "$VPC_IDS" ]; then
  echo "✅ No VPCs found. Already clean!"
  exit 0
fi

echo "Found VPCs:"
for vpc_id in $VPC_IDS; do
  VPC_NAME=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --region $REGION --query 'Vpcs[0].Tags[?Key==`Name`].Value | [0]' --output text)
  VPC_ENV=$(aws ec2 describe-vpcs --vpc-ids $vpc_id --region $REGION --query 'Vpcs[0].Tags[?Key==`Environment`].Value | [0]' --output text)
  echo "  • $vpc_id ($VPC_NAME - $VPC_ENV)"
done

echo ""
read -p "Type 'DELETE NOW' to confirm destruction: " CONFIRM

if [ "$CONFIRM" != "DELETE NOW" ]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "🗑️  Starting deletion process..."
echo ""

# Process each VPC
for VPC_ID in $VPC_IDS; do
  echo "================================================================"
  echo "Deleting VPC: $VPC_ID"
  echo "================================================================"

  # 1. Delete VPC Flow Logs
  echo "1. Deleting Flow Logs..."
  FLOW_LOG_IDS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC_ID" --region $REGION --query 'FlowLogs[].FlowLogId' --output text)
  for fl_id in $FLOW_LOG_IDS; do
    aws ec2 delete-flow-logs --flow-log-ids $fl_id --region $REGION 2>/dev/null && echo "   ✓ $fl_id" || echo "   ✗ $fl_id"
  done

  # 2. Delete NAT Gateways
  echo "2. Deleting NAT Gateways..."
  NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text)
  for nat_id in $NAT_IDS; do
    aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION && echo "   ✓ $nat_id"
  done

  # 3. Delete VPC Endpoints
  echo "3. Deleting VPC Endpoints..."
  VPCE_IDS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'VpcEndpoints[].VpcEndpointId' --output text)
  for vpce_id in $VPCE_IDS; do
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpce_id --region $REGION 2>/dev/null && echo "   ✓ $vpce_id"
  done

  echo ""
  echo "⏳ Waiting 90 seconds for NAT Gateways to delete..."
  sleep 90

  # 4. Release Elastic IPs
  echo "4. Releasing Elastic IPs..."
  EIP_ALLOCS=$(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text)
  for eip in $EIP_ALLOCS; do
    aws ec2 release-address --allocation-id $eip --region $REGION 2>/dev/null && echo "   ✓ $eip" || echo "   ✗ $eip (in use)"
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
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $REGION 2>/dev/null && echo "   ✓ $igw_id"
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

  # 10. Final VPC deletion
  echo "10. Deleting VPC..."
  aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION && echo "   ✅ $VPC_ID DELETED" || echo "   ⚠️  Failed (will retry)"

  echo ""
done

echo "================================================================"
echo "✅ CLEANUP COMPLETE"
echo "================================================================"
echo ""

# Verify
REMAINING=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=$PROJECT" --region $REGION --query 'Vpcs | length(@)' --output text)
echo "Remaining VPCs: $REMAINING"

if [ "$REMAINING" -eq 0 ]; then
  echo "✅ All VPCs successfully deleted!"
else
  echo "⚠️  Some VPCs may need another pass. Re-run this script."
fi
