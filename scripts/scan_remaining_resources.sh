#!/bin/bash

##############################################################################
# Remaining Resources Scanner
# Scans for orphaned CloudWatch Log Groups, IAM Roles, and CloudFormation Stacks
##############################################################################

set -e

REGION="us-east-1"
PROJECT="secure-vpc"

echo "================================================================"
echo "🔍 COMPREHENSIVE RESOURCE SCANNER"
echo "================================================================"
echo ""

# Initialize counters
TOTAL_LOG_GROUPS=0
TOTAL_IAM_ROLES=0
TOTAL_CFN_STACKS=0

# 1. Scan CloudWatch Log Groups
echo "───────────────────────────────────────────────────────────────"
echo "1️⃣  CloudWatch Log Groups"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Search for VPC-related log groups
VPC_LOGS=$(aws logs describe-log-groups \
  --region $REGION \
  --query "logGroups[?contains(logGroupName, 'vpc') || contains(logGroupName, '$PROJECT')].{Name:logGroupName,Size:storedBytes,Created:creationTime}" \
  --output json 2>/dev/null)

LOG_COUNT=$(echo "$VPC_LOGS" | jq '. | length')

if [ "$LOG_COUNT" -gt 0 ]; then
  echo "$VPC_LOGS" | jq -r '.[] | "  • \(.Name)\n    Size: \(.Size / 1024 / 1024 | floor)MB\n    Created: \(.Created / 1000 | strftime("%Y-%m-%d"))\n"'
  TOTAL_LOG_GROUPS=$LOG_COUNT
else
  echo "  ✅ No VPC/secure-vpc log groups found"
fi

echo "Total Log Groups: $TOTAL_LOG_GROUPS"
echo ""

# 2. Scan IAM Roles
echo "───────────────────────────────────────────────────────────────"
echo "2️⃣  IAM Roles (Terraform-managed)"
echo "───────────────────────────────────────────────────────────────"
echo ""

# List all IAM roles
ALL_ROLES=$(aws iam list-roles --query 'Roles[].RoleName' --output text 2>/dev/null)

if [ -n "$ALL_ROLES" ]; then
  for role in $ALL_ROLES; do
    # Get role tags
    TAGS=$(aws iam list-role-tags --role-name "$role" --output json 2>/dev/null)
    MANAGED_BY=$(echo "$TAGS" | jq -r '.Tags[]? | select(.Key=="ManagedBy") | .Value' 2>/dev/null)
    PROJECT_TAG=$(echo "$TAGS" | jq -r '.Tags[]? | select(.Key=="Project") | .Value' 2>/dev/null)

    # Check if Terraform-managed or related to secure-vpc
    if [ "$MANAGED_BY" == "Terraform" ] || [ "$PROJECT_TAG" == "$PROJECT" ] || [[ "$role" == *"vpc"* ]] || [[ "$role" == *"flow"* ]]; then
      echo "  • Role: $role"
      [ -n "$PROJECT_TAG" ] && echo "    Project: $PROJECT_TAG"
      [ -n "$MANAGED_BY" ] && echo "    ManagedBy: $MANAGED_BY"

      # Get attached policies
      POLICIES=$(aws iam list-attached-role-policies --role-name "$role" --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null)
      [ -n "$POLICIES" ] && echo "    Policies: $POLICIES"
      echo ""

      ((TOTAL_IAM_ROLES++)) || true
    fi
  done
else
  echo "  ✅ No IAM roles found"
fi

if [ $TOTAL_IAM_ROLES -eq 0 ]; then
  echo "  ✅ No Terraform-managed IAM roles found"
fi

echo "Total IAM Roles: $TOTAL_IAM_ROLES"
echo ""

# 3. Scan CloudFormation Stacks
echo "───────────────────────────────────────────────────────────────"
echo "3️⃣  CloudFormation Stacks"
echo "───────────────────────────────────────────────────────────────"
echo ""

CFN_STACKS=$(aws cloudformation list-stacks \
  --region $REGION \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE UPDATE_ROLLBACK_COMPLETE \
  --query 'StackSummaries[].{Name:StackName,Status:StackStatus,Created:CreationTime}' \
  --output json 2>/dev/null)

CFN_COUNT=$(echo "$CFN_STACKS" | jq '. | length')

if [ "$CFN_COUNT" -gt 0 ]; then
  echo "$CFN_STACKS" | jq -r '.[] | "  • Stack: \(.Name)\n    Status: \(.Status)\n    Created: \(.Created | split("T")[0])\n"'
  TOTAL_CFN_STACKS=$CFN_COUNT
else
  echo "  ✅ No CloudFormation stacks found"
fi

echo "Total CloudFormation Stacks: $TOTAL_CFN_STACKS"
echo ""

# 4. Additional Resources Check
echo "───────────────────────────────────────────────────────────────"
echo "4️⃣  Other Potential Resources"
echo "───────────────────────────────────────────────────────────────"
echo ""

# Check for SNS topics
echo "SNS Topics:"
SNS_TOPICS=$(aws sns list-topics --region $REGION --query 'Topics[].TopicArn' --output text 2>/dev/null | grep -i "vpc\|$PROJECT" || true)
if [ -n "$SNS_TOPICS" ]; then
  echo "$SNS_TOPICS" | while read topic; do
    echo "  • $topic"
  done
else
  echo "  ✅ No VPC-related SNS topics found"
fi
echo ""

# Check for CloudWatch Alarms
echo "CloudWatch Alarms:"
ALARMS=$(aws cloudwatch describe-alarms \
  --region $REGION \
  --query 'MetricAlarms[?contains(AlarmName, `vpc`) || contains(AlarmName, `'$PROJECT'`)].AlarmName' \
  --output text 2>/dev/null)
if [ -n "$ALARMS" ]; then
  echo "$ALARMS" | tr '\t' '\n' | while read alarm; do
    echo "  • $alarm"
  done
else
  echo "  ✅ No VPC-related CloudWatch alarms found"
fi
echo ""

# Summary
echo "================================================================"
echo "📊 FINAL SUMMARY"
echo "================================================================"
echo ""
echo "Resources found:"
echo "  • CloudWatch Log Groups: $TOTAL_LOG_GROUPS"
echo "  • IAM Roles (Terraform): $TOTAL_IAM_ROLES"
echo "  • CloudFormation Stacks: $TOTAL_CFN_STACKS"
echo ""

TOTAL_RESOURCES=$((TOTAL_LOG_GROUPS + TOTAL_IAM_ROLES + TOTAL_CFN_STACKS))

if [ $TOTAL_RESOURCES -eq 0 ]; then
  echo "✅ No additional Terraform-managed resources found!"
  echo ""
  echo "🎉 Your AWS account is completely clean!"
else
  echo "⚠️  Found $TOTAL_RESOURCES resource(s) that may need cleanup"
  echo ""
  echo "Would you like to delete these resources?"
fi

echo ""
echo "================================================================"
echo ""
