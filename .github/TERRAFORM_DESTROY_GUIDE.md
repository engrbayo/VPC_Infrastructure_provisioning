# Terraform Destroy Infrastructure Guide

## ⚠️ IMPORTANT: Destructive Operations

This guide explains how to safely destroy AWS infrastructure using the automated pipeline.

**READ THIS ENTIRE DOCUMENT BEFORE PROCEEDING**

---

## 🚨 Safety Features

The destroy workflow includes multiple safety mechanisms:

1. **Manual Trigger Only** - Never runs automatically
2. **Confirmation Word** - Must type "DESTROY" exactly
3. **Reason Required** - Must document why you're destroying
4. **Environment Selection** - Choose specific environment
5. **Manual Approval** - Requires human approval before destruction
6. **Verification** - Checks that resources were actually destroyed
7. **Audit Trail** - Creates destruction report artifact

---

## 📋 How to Destroy Infrastructure

### Step 1: Navigate to Actions Tab

```
https://github.com/engrbayo/VPC_provisioning/actions
```

### Step 2: Select "Terraform Destroy Infrastructure"

Click on the workflow name in the left sidebar.

### Step 3: Click "Run workflow"

You'll see a form with the following inputs:

#### Required Inputs:

1. **Environment to destroy**
   - Options: `dev`, `staging`, `prod`
   - Choose the environment you want to destroy

2. **Confirmation word**
   - Type exactly: `DESTROY` (case-sensitive)
   - This prevents accidental clicks

3. **Reason for destroying**
   - Document why you're destroying this infrastructure
   - Examples:
     - "Testing deployment pipeline"
     - "Decommissioning dev environment"
     - "Cost optimization - removing unused staging"

### Step 4: Review and Confirm

Click "Run workflow" (green button)

### Step 5: Wait for Validation

The workflow will:
1. Validate your confirmation word
2. Verify the environment
3. Display what will be destroyed
4. **PAUSE and wait for your approval**

### Step 6: Approve Destruction

1. Click on the running workflow
2. Find the "Terraform Destroy" job
3. Click **"Review deployments"**
4. Review the destruction plan
5. Click **"Approve and deploy"** if you're sure
   - Or click **"Reject"** to cancel

### Step 7: Monitor Progress

Watch the workflow as it:
1. Runs `terraform plan -destroy`
2. Runs `terraform destroy`
3. Verifies destruction
4. Creates destruction report

---

## 🎯 Example: Destroy Your 3 VPCs

You have 3 VPCs to destroy:
- `secure-vpc-vpc-dev`
- `secure-vpc-vpc-staging` (× 2)

### Destroy Dev Environment

1. Go to Actions → Terraform Destroy Infrastructure
2. Click "Run workflow"
3. Fill in:
   - Environment: `dev`
   - Confirmation: `DESTROY`
   - Reason: "Cleaning up test deployments"
4. Click "Run workflow"
5. Wait for approval prompt
6. Review and approve

### Destroy Staging Environment(s)

Repeat the process for `staging`:

1. Go to Actions → Terraform Destroy Infrastructure
2. Click "Run workflow"
3. Fill in:
   - Environment: `staging`
   - Confirmation: `DESTROY`
   - Reason: "Removing duplicate staging VPCs"
4. Click "Run workflow"
5. Wait for approval prompt
6. Review and approve

**Note**: Since you have 2 staging VPCs, you may need to run this twice or clean up manually using AWS CLI.

---

## 🔧 Alternative: Destroy All at Once (Local)

If you want to destroy all 3 VPCs quickly, run locally:

### Step 1: Destroy Dev
```bash
# Set environment to dev
export TF_VAR_environment="dev"

# Destroy
terraform destroy -auto-approve
```

### Step 2: Destroy Staging
```bash
# Set environment to staging
export TF_VAR_environment="staging"

# Destroy
terraform destroy -auto-approve
```

### Step 3: Verify All Gone
```bash
# List all VPCs with your project tag
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=secure-vpc" \
  --region us-east-1 \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],Tags[?Key==`Environment`].Value|[0]]' \
  --output table
```

---

## 🚀 Quick Cleanup Script

I've created a script to destroy all environments at once:

```bash
# Run the cleanup script
./scripts/destroy_all_environments.sh
```

This will:
1. List all VPCs
2. Ask for confirmation
3. Destroy each environment
4. Verify everything is cleaned up

---

## 🛡️ Before You Destroy

### ✅ Checklist

- [ ] Backed up any important data
- [ ] Verified this is the correct environment
- [ ] Notified team members (if applicable)
- [ ] Documented the reason for destruction
- [ ] Confirmed no active workloads are running
- [ ] Checked that no production services depend on this VPC

### ⚠️ Things to Know

1. **VPC Destruction is Permanent**
   - No undo button
   - All resources are deleted
   - Data in RDS, ElastiCache, etc. will be lost

2. **Some Resources Take Time to Delete**
   - NAT Gateways: ~2-3 minutes
   - Elastic IPs: Released after NAT deletion
   - KMS Keys: 7-30 day waiting period

3. **Terraform State**
   - Local state file will be updated
   - Remote state (if configured) will be updated
   - Keep state files for audit purposes

4. **Costs**
   - Most costs stop immediately
   - S3 storage costs continue until buckets are emptied
   - KMS keys may have minimum billing period

---

## 🔍 Troubleshooting

### Error: "DependencyViolation"

**Problem**: Resources still in use

**Solution**:
1. Check for resources not managed by Terraform
2. Delete manually via AWS Console
3. Run destroy again

### Error: "BucketNotEmpty"

**Problem**: S3 bucket contains objects

**Solution**:
```bash
# Empty the bucket
aws s3 rm s3://secure-vpc-flow-logs-staging-* --recursive --region us-east-1

# Then run destroy again
terraform destroy
```

### Error: "Timeout waiting for NAT Gateway deletion"

**Problem**: NAT Gateways take time to delete

**Solution**:
Wait 5 minutes and run destroy again:
```bash
sleep 300
terraform destroy
```

### Multiple VPCs with Same Environment

**Problem**: You have 2 staging VPCs

**Solution**:
```bash
# List all VPCs
aws ec2 describe-vpcs \
  --filters "Name=tag:Environment,Values=staging" \
  --region us-east-1

# Delete each manually
aws ec2 delete-vpc --vpc-id vpc-XXXXXXXX --region us-east-1
```

---

## 📊 What Gets Destroyed

| Resource Type | Count | Description |
|--------------|-------|-------------|
| **VPC** | 1 | Main VPC (10.0.0.0/16) |
| **Subnets** | 6 | 2 public, 2 private, 2 data |
| **Internet Gateway** | 1 | Entry point for internet traffic |
| **NAT Gateways** | 2 | One per availability zone |
| **Elastic IPs** | 2 | Associated with NAT Gateways |
| **Route Tables** | 4 | Public, private (×2), data |
| **Security Groups** | 5 | ALB, App, DB, Bastion, VPC Endpoints |
| **Network ACLs** | 3 | One per tier |
| **VPC Endpoints** | 9 | S3, EC2, ECR, Logs, Secrets, SSM |
| **Flow Logs** | 2 | CloudWatch + S3 |
| **CloudWatch Log Group** | 1 | /aws/vpc/secure-vpc-{env} |
| **S3 Buckets** | 2 | Flow logs + access logs |
| **IAM Roles** | 1 | Flow logs role |
| **KMS Keys** | 2 | CloudWatch + S3 encryption |

**Total**: ~40-50 resources per environment

---

## 💰 Cost After Destruction

| Resource | Before | After |
|----------|--------|-------|
| NAT Gateways | ~$65/month | $0 |
| VPC Endpoints | ~$15/month | $0 |
| Data Transfer | Variable | $0 |
| S3 Storage | ~$5/month | ~$1 (until deleted) |
| KMS Keys | ~$2/month | ~$1 (scheduled deletion) |
| **Total** | ~$85/month | ~$2/month |

S3 and KMS costs continue briefly until final cleanup.

---

## 🔐 Security Considerations

### Audit Trail

Every destruction is logged:
- GitHub Actions logs (90 days)
- Destruction report artifact (90 days)
- Who triggered it
- When it happened
- Why it was destroyed

### Access Control

Restrict who can run destroy workflows:
1. Go to repository settings
2. Environments → Create "destruction-approval-{env}"
3. Add required reviewers
4. Only those users can approve destructions

### Preventing Accidents

The workflow has multiple safety checks:
```yaml
1. Manual trigger only (no automatic)
2. Confirmation word required
3. Reason documentation required
4. Manual approval required
5. Destruction plan review
6. Post-destruction verification
```

---

## 📝 Best Practices

### 1. Always Document the Reason
```
Good reasons:
✅ "Testing deployment pipeline before production"
✅ "Decommissioning unused dev environment for cost savings"
✅ "Recreating infrastructure to test disaster recovery"

Bad reasons:
❌ "Testing"
❌ "Just because"
❌ "Quick cleanup"
```

### 2. Notify the Team
Send a message in Slack/Teams:
```
🚨 Infrastructure Destruction Notice
Environment: staging
Reason: Removing duplicate VPCs
Scheduled: 2026-02-09 10:00 UTC
Contact @yourname with questions
```

### 3. Backup Important Data
Before destroying:
```bash
# Export RDS snapshot
aws rds create-db-snapshot \
  --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-final-backup

# Download S3 data
aws s3 sync s3://mybucket ./backup/
```

### 4. Verify Before Approving
Check the destruction plan:
```
Plan: 0 to add, 0 to change, 47 to destroy.

Changes to Outputs:
  - vpc_id = "vpc-0d74d5ec7294c0b6f" -> null
```

Make sure the VPC ID matches what you expect!

---

## 🚀 Re-deploying After Destruction

To recreate the infrastructure:

### Via GitHub Actions
1. Push to main branch
2. Workflow runs automatically
3. Approve deployment
4. Infrastructure recreated

### Locally
```bash
terraform apply
```

---

## 📞 Need Help?

- **Stuck?** Check the troubleshooting section
- **Questions?** Open a GitHub issue
- **Emergency?** Contact your AWS administrator

---

## ⚡ Quick Command Reference

```bash
# List all VPCs
aws ec2 describe-vpcs --region us-east-1

# Destroy via Terraform
terraform destroy

# Destroy specific environment
export TF_VAR_environment="staging"
terraform destroy

# Emergency: Delete VPC directly
aws ec2 delete-vpc --vpc-id vpc-XXXXX --region us-east-1

# Verify everything is gone
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=secure-vpc" \
  --region us-east-1
```

---

**⚠️ Remember: Infrastructure destruction is PERMANENT. Always double-check before approving!**
