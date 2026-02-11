#!/bin/bash

#######################################################
# AWS VPC Infrastructure Cleanup Script
# Deletes all resources created by Terraform deployment
#######################################################

set -e

VPC_ID="vpc-0d74d5ec7294c0b6f"
REGION="us-east-1"
PROJECT="secure-vpc"
ENVIRONMENT="staging"

echo "========================================="
echo "🗑️  Infrastructure Cleanup Script"
echo "========================================="
echo "VPC ID: $VPC_ID"
echo "Region: $REGION"
echo ""
read -p "⚠️  This will DELETE all infrastructure. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# 1. Delete VPC Flow Logs
echo "1️⃣  Deleting VPC Flow Logs..."
FLOW_LOG_IDS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$VPC_ID" --region $REGION --query 'FlowLogs[].FlowLogId' --output text)
for flow_id in $FLOW_LOG_IDS; do
  echo "   Deleting Flow Log: $flow_id"
  aws ec2 delete-flow-logs --flow-log-ids $flow_id --region $REGION
done

# 2. Delete CloudWatch Log Group
echo ""
echo "2️⃣  Deleting CloudWatch Log Group..."
aws logs delete-log-group --log-group-name "/aws/vpc/${PROJECT}-${ENVIRONMENT}" --region $REGION 2>/dev/null && echo "   ✅ Deleted" || echo "   ⚠️  Not found"

# 3. Delete S3 Buckets
echo ""
echo "3️⃣  Deleting S3 Buckets..."
for bucket in $(aws s3 ls --region $REGION | grep "${PROJECT}-.*-${ENVIRONMENT}" | awk '{print $3}'); do
  echo "   Emptying: $bucket"
  aws s3 rm s3://$bucket --recursive --region $REGION --quiet
  echo "   Deleting: $bucket"
  aws s3 rb s3://$bucket --region $REGION && echo "   ✅ Deleted" || echo "   ⚠️  Failed"
done

# 4. Delete NAT Gateways
echo ""
echo "4️⃣  Deleting NAT Gateways..."
for nat_id in $(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NatGateways[?State!=`deleted`].NatGatewayId' --output text); do
  echo "   Deleting NAT Gateway: $nat_id"
  aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION
done

echo "   ⏳ Waiting 3 minutes for NAT Gateways to delete..."
sleep 180

# 5. Release Elastic IPs
echo ""
echo "5️⃣  Releasing Elastic IPs..."
for eip in $(aws ec2 describe-addresses --region $REGION --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text); do
  echo "   Releasing: $eip"
  aws ec2 release-address --allocation-id $eip --region $REGION 2>/dev/null && echo "   ✅ Released" || echo "   ⚠️  In use"
done

# 6. Delete VPC Endpoints
echo ""
echo "6️⃣  Deleting VPC Endpoints..."
for vpce in $(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'VpcEndpoints[].VpcEndpointId' --output text); do
  echo "   Deleting: $vpce"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpce --region $REGION
done
sleep 10

# 7. Delete Network ACLs (custom ones)
echo ""
echo "7️⃣  Deleting Network ACLs..."
for nacl in $(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text); do
  echo "   Deleting: $nacl"
  aws ec2 delete-network-acl --network-acl-id $nacl --region $REGION 2>/dev/null && echo "   ✅ Deleted" || echo "   ⚠️  Failed"
done

# 8. Delete Subnets
echo ""
echo "8️⃣  Deleting Subnets..."
for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'Subnets[].SubnetId' --output text); do
  echo "   Deleting: $subnet"
  aws ec2 delete-subnet --subnet-id $subnet --region $REGION 2>/dev/null && echo "   ✅ Deleted" || echo "   ⚠️  In use"
done
sleep 5

# 9. Delete Route Tables
echo ""
echo "9️⃣  Deleting Route Tables..."
for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'RouteTables[].RouteTableId' --output text); do
  IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids $rt --region $REGION --query 'RouteTables[0].Associations[?Main==`true`]' --output text)
  if [ -z "$IS_MAIN" ]; then
    echo "   Deleting: $rt"
    aws ec2 delete-route-table --route-table-id $rt --region $REGION 2>/dev/null && echo "   ✅ Deleted" || echo "   ⚠️  In use"
  fi
done
sleep 5

# 10. Detach and Delete Internet Gateway
echo ""
echo "🔟 Deleting Internet Gateway..."
for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region $REGION --query 'InternetGateways[].InternetGatewayId' --output text); do
  echo "   Detaching: $igw"
  aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $VPC_ID --region $REGION
  echo "   Deleting: $igw"
  aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $REGION && echo "   ✅ Deleted" || echo "   ⚠️  Failed"
done

# 11. Delete Security Groups
echo ""
echo "1️⃣1️⃣  Deleting Security Groups..."
for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'SecurityGroups[].GroupId' --output text); do
  SG_NAME=$(aws ec2 describe-security-groups --group-ids $sg --region $REGION --query 'SecurityGroups[0].GroupName' --output text)
  if [ "$SG_NAME" != "default" ]; then
    echo "   Deleting: $sg ($SG_NAME)"
    aws ec2 delete-security-group --group-id $sg --region $REGION 2>/dev/null && echo "   ✅ Deleted" || echo "   ⚠️  In use"
  fi
done

# 12. Delete VPC
echo ""
echo "1️⃣2️⃣  Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION && echo "   ✅ VPC DELETED!" || echo "   ⚠️  VPC deletion failed"

# 13. Delete IAM Roles
echo ""
echo "1️⃣3️⃣  Deleting IAM Roles..."
ROLE_NAME="${PROJECT}-flow-logs-${ENVIRONMENT}"
aws iam delete-role-policy --role-name $ROLE_NAME --policy-name FlowLogsPolicy 2>/dev/null
aws iam delete-role --role-name $ROLE_NAME 2>/dev/null && echo "   ✅ Deleted $ROLE_NAME" || echo "   ⚠️  Not found"

# 14. Schedule KMS Keys for Deletion
echo ""
echo "1️⃣4️⃣  Scheduling KMS Keys for deletion..."
for key_id in $(aws kms list-aliases --region $REGION --query "Aliases[?starts_with(AliasName, 'alias/${PROJECT}-')].TargetKeyId" --output text); do
  echo "   Scheduling: $key_id (7-day waiting period)"
  aws kms schedule-key-deletion --key-id $key_id --pending-window-in-days 7 --region $REGION 2>/dev/null && echo "   ✅ Scheduled" || echo "   ⚠️  Already scheduled"
done

echo ""
echo "========================================="
echo "✅ Cleanup Complete!"
echo "========================================="
echo ""
echo "Summary:"
echo "- VPC and networking resources deleted"
echo "- S3 buckets emptied and removed"
echo "- CloudWatch logs deleted"
echo "- IAM roles removed"
echo "- KMS keys scheduled for deletion (7 days)"
echo ""
echo "⚠️  Note: If any resources failed to delete, wait a few"
echo "    minutes and run this script again."
echo ""
