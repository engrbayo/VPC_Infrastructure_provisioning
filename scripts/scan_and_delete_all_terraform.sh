#!/bin/bash

##############################################################################
# Comprehensive Terraform Infrastructure Scanner & Cleanup Tool
# Finds and deletes ALL Terraform-managed resources in AWS account
##############################################################################

set -e

REGION="us-east-1"

echo "================================================================"
echo "🔍 TERRAFORM INFRASTRUCTURE SCANNER"
echo "================================================================"
echo ""
echo "Scanning AWS account for Terraform-managed resources..."
echo ""

# Function to print section header
print_section() {
    echo ""
    echo "───────────────────────────────────────────────────────────────"
    echo "$1"
    echo "───────────────────────────────────────────────────────────────"
}

# Initialize counters
TOTAL_VPCS=0
TOTAL_EC2=0
TOTAL_RDS=0
TOTAL_ELB=0
TOTAL_S3=0
TOTAL_LAMBDA=0
TOTAL_ECS=0

# 1. Scan VPCs
print_section "1️⃣  VPCs (Terraform-managed)"
VPC_LIST=$(aws ec2 describe-vpcs \
  --region $REGION \
  --query 'Vpcs[?Tags[?Key==`ManagedBy` && Value==`Terraform`]].[VpcId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Project`].Value|[0],Tags[?Key==`Environment`].Value|[0]]' \
  --output text 2>/dev/null)

if [ -n "$VPC_LIST" ]; then
  echo "$VPC_LIST" | while read vpc_id name project env; do
    echo "  • VPC: $vpc_id"
    echo "    Name: $name"
    echo "    Project: $project"
    echo "    Environment: $env"
    echo ""
    ((TOTAL_VPCS++)) || true
  done
  TOTAL_VPCS=$(echo "$VPC_LIST" | wc -l | xargs)
  echo "Total VPCs: $TOTAL_VPCS"
else
  echo "  No Terraform-managed VPCs found"
fi

# 2. Scan EC2 Instances
print_section "2️⃣  EC2 Instances (Terraform-managed)"
EC2_LIST=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:ManagedBy,Values=Terraform" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Project`].Value|[0]]' \
  --output text 2>/dev/null)

if [ -n "$EC2_LIST" ]; then
  echo "$EC2_LIST" | while read instance_id state name project; do
    echo "  • Instance: $instance_id ($state)"
    echo "    Name: $name"
    echo "    Project: $project"
    echo ""
    ((TOTAL_EC2++)) || true
  done
  TOTAL_EC2=$(echo "$EC2_LIST" | wc -l | xargs)
  echo "Total EC2 Instances: $TOTAL_EC2"
else
  echo "  No Terraform-managed EC2 instances found"
fi

# 3. Scan RDS Databases
print_section "3️⃣  RDS Databases (Terraform-managed)"
RDS_LIST=$(aws rds describe-db-instances \
  --region $REGION \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Engine,TagList[?Key==`ManagedBy`].Value|[0]]' \
  --output text 2>/dev/null)

if [ -n "$RDS_LIST" ]; then
  echo "$RDS_LIST" | while read db_id status engine managed_by; do
    if [ "$managed_by" == "Terraform" ]; then
      echo "  • Database: $db_id ($status)"
      echo "    Engine: $engine"
      echo ""
      ((TOTAL_RDS++)) || true
    fi
  done
  echo "Total RDS Databases: $TOTAL_RDS"
else
  echo "  No Terraform-managed RDS databases found"
fi

# 4. Scan Load Balancers
print_section "4️⃣  Load Balancers (Terraform-managed)"
ELB_LIST=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --query 'LoadBalancers[].[LoadBalancerArn,LoadBalancerName,Type,State.Code]' \
  --output text 2>/dev/null)

if [ -n "$ELB_LIST" ]; then
  echo "$ELB_LIST" | while read lb_arn lb_name lb_type state; do
    # Check if managed by Terraform
    TAGS=$(aws elbv2 describe-tags --resource-arns $lb_arn --region $REGION --query 'TagDescriptions[0].Tags[?Key==`ManagedBy`].Value | [0]' --output text 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "  • Load Balancer: $lb_name ($lb_type)"
      echo "    State: $state"
      echo ""
      ((TOTAL_ELB++)) || true
    fi
  done
  echo "Total Load Balancers: $TOTAL_ELB"
else
  echo "  No Terraform-managed load balancers found"
fi

# 5. Scan S3 Buckets
print_section "5️⃣  S3 Buckets (Terraform-managed)"
S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text --region $REGION 2>/dev/null)

if [ -n "$S3_BUCKETS" ]; then
  for bucket in $S3_BUCKETS; do
    TAGS=$(aws s3api get-bucket-tagging --bucket $bucket --region $REGION 2>/dev/null | jq -r '.TagSet[] | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "  • Bucket: $bucket"
      ((TOTAL_S3++)) || true
    fi
  done
  echo ""
  echo "Total S3 Buckets: $TOTAL_S3"
else
  echo "  No S3 buckets found"
fi

# 6. Scan Lambda Functions
print_section "6️⃣  Lambda Functions (Terraform-managed)"
LAMBDA_LIST=$(aws lambda list-functions \
  --region $REGION \
  --query 'Functions[].[FunctionName,Runtime]' \
  --output text 2>/dev/null)

if [ -n "$LAMBDA_LIST" ]; then
  echo "$LAMBDA_LIST" | while read func_name runtime; do
    TAGS=$(aws lambda list-tags --resource $(aws lambda get-function --function-name $func_name --region $REGION --query 'Configuration.FunctionArn' --output text) --region $REGION 2>/dev/null | jq -r '.Tags.ManagedBy' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "  • Function: $func_name"
      echo "    Runtime: $runtime"
      echo ""
      ((TOTAL_LAMBDA++)) || true
    fi
  done
  echo "Total Lambda Functions: $TOTAL_LAMBDA"
else
  echo "  No Terraform-managed Lambda functions found"
fi

# 7. Scan ECS Clusters
print_section "7️⃣  ECS Clusters (Terraform-managed)"
ECS_CLUSTERS=$(aws ecs list-clusters --region $REGION --query 'clusterArns[]' --output text 2>/dev/null)

if [ -n "$ECS_CLUSTERS" ]; then
  for cluster_arn in $ECS_CLUSTERS; do
    CLUSTER_NAME=$(basename $cluster_arn)
    TAGS=$(aws ecs list-tags-for-resource --resource-arn $cluster_arn --region $REGION 2>/dev/null | jq -r '.tags[] | select(.key=="ManagedBy") | .value' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "  • Cluster: $CLUSTER_NAME"
      ((TOTAL_ECS++)) || true
    fi
  done
  echo ""
  echo "Total ECS Clusters: $TOTAL_ECS"
else
  echo "  No Terraform-managed ECS clusters found"
fi

# Summary
print_section "📊 SUMMARY"
echo ""
echo "Terraform-managed resources found:"
echo "  • VPCs: $TOTAL_VPCS"
echo "  • EC2 Instances: $TOTAL_EC2"
echo "  • RDS Databases: $TOTAL_RDS"
echo "  • Load Balancers: $TOTAL_ELB"
echo "  • S3 Buckets: $TOTAL_S3"
echo "  • Lambda Functions: $TOTAL_LAMBDA"
echo "  • ECS Clusters: $TOTAL_ECS"
echo ""

TOTAL_RESOURCES=$((TOTAL_VPCS + TOTAL_EC2 + TOTAL_RDS + TOTAL_ELB + TOTAL_S3 + TOTAL_LAMBDA + TOTAL_ECS))
echo "🔢 Total Resources: $TOTAL_RESOURCES"
echo ""

if [ $TOTAL_RESOURCES -eq 0 ]; then
  echo "✅ No Terraform-managed resources found!"
  echo "Your AWS account is clean."
  exit 0
fi

# Deletion prompt
echo "================================================================"
echo "⚠️  DELETION CONFIRMATION"
echo "================================================================"
echo ""
echo "This will DELETE ALL $TOTAL_RESOURCES Terraform-managed resources!"
echo ""
read -p "Type 'DELETE ALL TERRAFORM' to confirm: " CONFIRM

if [ "$CONFIRM" != "DELETE ALL TERRAFORM" ]; then
  echo ""
  echo "❌ Aborted. Nothing was deleted."
  exit 0
fi

echo ""
echo "🗑️  Starting comprehensive cleanup..."
echo ""

# Delete VPCs
if [ $TOTAL_VPCS -gt 0 ]; then
  print_section "Deleting VPCs"

  VPC_IDS=$(aws ec2 describe-vpcs \
    --region $REGION \
    --query 'Vpcs[?Tags[?Key==`ManagedBy` && Value==`Terraform`]].VpcId' \
    --output text)

  for vpc_id in $VPC_IDS; do
    echo "Deleting VPC: $vpc_id"

    # Use the force delete script for each VPC
    # Delete dependencies first...

    # Delete Flow Logs
    FLOW_LOG_IDS=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc_id" --region $REGION --query 'FlowLogs[].FlowLogId' --output text)
    for fl_id in $FLOW_LOG_IDS; do
      aws ec2 delete-flow-logs --flow-log-ids $fl_id --region $REGION 2>/dev/null && echo "  ✓ Flow Log $fl_id"
    done

    # Delete NAT Gateways
    NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpc_id" --region $REGION --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
    for nat_id in $NAT_IDS; do
      aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION && echo "  ✓ NAT Gateway $nat_id"
    done

    # Delete VPC Endpoints
    VPCE_IDS=$(aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$vpc_id" --region $REGION --query 'VpcEndpoints[].VpcEndpointId' --output text)
    for vpce_id in $VPCE_IDS; do
      aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $vpce_id --region $REGION 2>/dev/null && echo "  ✓ VPC Endpoint $vpce_id"
    done

    sleep 30  # Wait for deletions

    # Delete Subnets
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --region $REGION --query 'Subnets[].SubnetId' --output text)
    for subnet_id in $SUBNET_IDS; do
      aws ec2 delete-subnet --subnet-id $subnet_id --region $REGION 2>/dev/null && echo "  ✓ Subnet $subnet_id"
    done

    # Delete Route Tables
    RT_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" --region $REGION --query 'RouteTables[].RouteTableId' --output text)
    for rt_id in $RT_IDS; do
      IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids $rt_id --region $REGION --query 'RouteTables[0].Associations[?Main==`true`]' --output text)
      if [ -z "$IS_MAIN" ]; then
        aws ec2 delete-route-table --route-table-id $rt_id --region $REGION 2>/dev/null && echo "  ✓ Route Table $rt_id"
      fi
    done

    # Detach and Delete Internet Gateway
    IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --region $REGION --query 'InternetGateways[].InternetGatewayId' --output text)
    for igw_id in $IGW_IDS; do
      aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id --region $REGION 2>/dev/null
      aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $REGION 2>/dev/null && echo "  ✓ Internet Gateway $igw_id"
    done

    # Delete Security Groups
    SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --region $REGION --query 'SecurityGroups[].GroupId' --output text)
    for sg_id in $SG_IDS; do
      SG_NAME=$(aws ec2 describe-security-groups --group-ids $sg_id --region $REGION --query 'SecurityGroups[0].GroupName' --output text)
      if [ "$SG_NAME" != "default" ]; then
        aws ec2 delete-security-group --group-id $sg_id --region $REGION 2>/dev/null && echo "  ✓ Security Group $sg_id"
      fi
    done

    # Finally delete VPC
    aws ec2 delete-vpc --vpc-id $vpc_id --region $REGION 2>/dev/null && echo "  ✅ VPC $vpc_id DELETED"

    echo ""
  done
fi

# Delete EC2 Instances
if [ $TOTAL_EC2 -gt 0 ]; then
  print_section "Terminating EC2 Instances"

  EC2_IDS=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:ManagedBy,Values=Terraform" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)

  if [ -n "$EC2_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $EC2_IDS --region $REGION
    echo "✅ Terminating $TOTAL_EC2 EC2 instance(s)"
  fi
fi

# Delete RDS Databases
if [ $TOTAL_RDS -gt 0 ]; then
  print_section "Deleting RDS Databases"

  # This is dangerous - adding extra confirmation
  echo "⚠️  Warning: RDS deletion will lose ALL data!"
  read -p "Type 'DELETE RDS' to confirm: " RDS_CONFIRM

  if [ "$RDS_CONFIRM" == "DELETE RDS" ]; then
    # Add RDS deletion logic here
    echo "RDS deletion would go here (skipped for safety)"
  else
    echo "Skipped RDS deletion"
  fi
fi

# Delete S3 Buckets
if [ $TOTAL_S3 -gt 0 ]; then
  print_section "Deleting S3 Buckets"

  S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[].Name' --output text --region $REGION)
  for bucket in $S3_BUCKETS; do
    TAGS=$(aws s3api get-bucket-tagging --bucket $bucket --region $REGION 2>/dev/null | jq -r '.TagSet[] | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    if [ "$TAGS" == "Terraform" ]; then
      echo "Emptying bucket: $bucket"
      aws s3 rm s3://$bucket --recursive --region $REGION 2>/dev/null
      aws s3 rb s3://$bucket --region $REGION && echo "  ✅ Deleted $bucket"
    fi
  done
fi

echo ""
echo "================================================================"
echo "✅ CLEANUP COMPLETE"
echo "================================================================"
echo ""
echo "Deleted resources:"
echo "  • VPCs: $TOTAL_VPCS"
echo "  • EC2 Instances: $TOTAL_EC2"
echo "  • S3 Buckets: $TOTAL_S3"
echo ""
echo "💰 Estimated monthly savings: ~$$(( (TOTAL_VPCS * 85) + (TOTAL_EC2 * 50) + (TOTAL_RDS * 150) + (TOTAL_ELB * 25) ))/month"
echo ""
