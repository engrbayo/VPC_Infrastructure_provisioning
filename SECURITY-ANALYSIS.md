# AWS VPC Infrastructure: Security Engineering Analysis

**Author:** Senior Cloud Security Engineer Review
**Project:** secure-vpc
**Environment:** Staging (us-east-1)
**Codebase:** Terraform + GitHub Actions + KICS
**Date:** February 14, 2026

---

## 1. THE NEED FOR THIS PROJECT

### The Problem This Solves

Most organizations that move to AWS start by deploying resources directly into a default VPC with minimal controls. That approach works for a quick proof-of-concept but creates a flat, perimeter-less network where every resource can reach every other resource, and workloads are mixed regardless of sensitivity. This project solves that problem by building a **production-grade, security-first network foundation** before any application is deployed.

The core engineering decision here is **network segmentation as a security primitive**. Before you can enforce least privilege at the application layer, you need it at the network layer. This VPC is that foundation.

### What Business Problem It Addresses

```
WITHOUT this project:         WITH this project:
──────────────────────────    ──────────────────────────
• Flat network = blast        • Tiered network = contained
  radius is the entire VPC      breach radius per subnet

• No audit trail for          • VPC Flow Logs capture every
  network traffic               connection attempt

• AWS API calls route          • VPC Endpoints keep traffic
  through the internet           inside AWS backbone

• Ad-hoc security rules        • Codified, reviewed, version-
  live in someone's head         controlled infrastructure

• No automated scanning        • KICS catches misconfigurations
  before deployment              before they reach production
```

---

## 2. WHAT WAS PROVISIONED AND WHY

### 2.1 Core Network — `vpc.tf`

**What was built:**
```
VPC: 10.0.0.0/16 (65,536 addresses)
├── Public Subnets:  10.0.1.0/24, 10.0.2.0/24   (AZ: 1a, 1b)
├── Private Subnets: 10.0.10.0/24, 10.0.20.0/24  (AZ: 1a, 1b)
└── Data Subnets:    10.0.100.0/24, 10.0.200.0/24 (AZ: 1a, 1b)
```

**Why each tier exists:**

| Tier | Reachable From | Reaches | Purpose |
|------|---------------|---------|---------|
| Public | Internet | Internet + Private | Load balancers, NAT gateways, bastion |
| Private | Public tier only | Internet (via NAT) + Data | Application servers, ECS tasks |
| Data | Private tier only | Nowhere (no route 0.0.0.0/0) | Databases, caches, critical data stores |

The **Data subnet has no route to the internet** — not through NAT, not through IGW. This is the single most important network control in the entire project. A compromised application server in the private subnet cannot directly reach out to the internet from a database instance. The attacker would need to pivot through the application tier first, which creates detection opportunities.

`enable_dns_hostnames = true` and `enable_dns_support = true` are required for VPC Endpoints to resolve private DNS names — meaning services like Secrets Manager resolve to a private IP inside your VPC, not a public one.

Multi-AZ deployment (2 AZs for all tiers) ensures that a single availability zone failure does not take down the entire workload. This is not just a resilience decision — it is also a security decision. A DoS attack targeting one AZ should not bring down all capacity.

---

### 2.2 Internet Gateway + NAT Gateways — `vpc.tf` + `nat.tf`

**What was built:**
- 1 Internet Gateway (IGW) attached to the VPC
- 2 NAT Gateways (one per AZ, Elastic IP each)
- Per-AZ NAT is the default (`single_nat_gateway = false`)

**Why this matters from a security standpoint:**

The IGW is the only path for bidirectional internet traffic, and it is only attached to the public subnet route table. Private and data subnets have no IGW route — only the public tier does.

NAT Gateways allow private subnet instances to initiate outbound connections (for OS patches, pulling container images, calling external APIs) **without ever accepting inbound connections from the internet**. NAT is stateful and only translates outbound-initiated flows. An attacker on the internet cannot initiate a TCP connection to any resource in the private subnet through the NAT — there is no listening socket to reach.

**Per-AZ NAT is the correct security choice** despite the cost. A single NAT creates a cross-AZ dependency: if the AZ hosting the NAT fails, *all* outbound internet from private subnets is cut, even if the application is running fine in the surviving AZ. The `single_nat_gateway = true` option exists only for development cost savings, and `terraform.tfvars` correctly leaves it `false` for staging.

---

### 2.3 Security Groups — `security_groups.tf`

**Five security groups provisioned:**

```
alb-sg         → Accepts: 0.0.0.0/0 on 443/80
                  Allows to: app-sg on 8080

app-sg         → Accepts: alb-sg on 8080, bastion-sg on 22
                  Allows to: db-sg on 5432, internet on 443 (via NAT)

db-sg          → Accepts: app-sg on 5432, bastion-sg on 5432
                  Allows to: VPC CIDR on 5432 (logging/monitoring only)

bastion-sg     → Accepts: allowed_ssh_cidrs on 22 (empty by default!)
                  Allows to: everywhere (for management traffic)

vpc-endpoints-sg → Accepts: VPC CIDR on 443
                   Allows to: VPC CIDR on 443
```

**The most important design decision here is source/destination chaining** — security groups reference other security groups rather than CIDR blocks wherever possible. This means:

- When you add a new app server, it automatically gets database access because it inherits the `app-sg` group. You do not need to manually add its IP to the database rule.
- If the ALB's IP changes (it will — ALBs are not single IPs), the app server rule `alb-sg on 8080` remains valid. No rule updates needed.
- The blast radius of a compromised component is limited. If an app server is compromised, its security group allows it to reach only the database on 5432. It cannot port-scan the rest of the VPC.

**`allowed_ssh_cidrs = []` by default** — the bastion has no SSH inbound rules unless you explicitly pass a CIDR. This is the correct default. SSH access should be explicit and intentional, not inherited from a template.

The **database security group** only allows traffic from `app-sg` and `bastion-sg`. No CIDR-based rules. The database is invisible to everything that does not carry one of those two security group labels — including anything in the public subnet.

---

### 2.4 Network ACLs — `nacls.tf`

**Three NACLs provisioned:**

| NACL | Applied To | Inbound | Outbound |
|------|-----------|---------|---------|
| public-nacl | Public subnets | 80, 443, 22 (conditional), ephemeral (1024-65535) | 80, 443, VPC CIDR, ephemeral |
| private-nacl | Private subnets | VPC CIDR, ephemeral | 80, 443, VPC CIDR, ephemeral |
| data-nacl | Data subnets | VPC CIDR only, ephemeral | VPC CIDR only |

**Why NACLs in addition to security groups?**

Security groups are stateful — if you allow inbound traffic, the return traffic is automatically permitted regardless of outbound rules. NACLs are stateless — you must explicitly allow both directions, including the ephemeral port range (1024-65535) for return traffic.

This creates **two independent enforcement points**:

1. NACL at the subnet boundary — coarse-grained, stateless, subnet-level
2. Security group at the resource boundary — fine-grained, stateful, instance-level

An attacker who somehow bypasses a security group (misconfiguration, AWS bug, IAM privilege escalation that modifies SG rules) still hits the NACL. And vice versa. Defense in depth is not redundancy — it is independent failure domains.

The **data NACL is the most restrictive**: VPC CIDR in and out only. Even if someone adds a rogue 0.0.0.0/0 security group rule on a database instance, the NACL at the subnet level will drop that traffic. The NACL is the backstop.

---

### 2.5 VPC Flow Logs — `flow_logs.tf`

**What was provisioned:**
- KMS key with key rotation enabled (90-day rotation)
- CloudWatch Log Group with KMS encryption + 7-day retention
- S3 bucket (flow logs destination) with:
  - AES-256 server-side encryption
  - Object versioning enabled
  - Lifecycle policy: Standard → Infrequent Access at 30 days → Glacier at 90 days → Delete at 365 days
  - Access logging bucket (separate S3 bucket logging access to the flow logs bucket)
- IAM Role with least-privilege policy for VPC to write to CloudWatch
- Two Flow Log resources: one to CloudWatch (operational), one to S3 in Parquet format (analytics/Athena)

**Why Flow Logs are a security-critical control:**

Flow Logs capture every accepted and rejected network connection — source IP, destination IP, source port, destination port, protocol, bytes, packets, start/end time, and action (ACCEPT/REJECT). They are the network equivalent of an audit log.

Without Flow Logs, if an attacker exfiltrates data via a database connection that was left open, you have zero forensic evidence at the network layer. With Flow Logs, you can answer:
- Did anything in the private subnet make an unexpected outbound connection?
- What IP addresses connected to the load balancer before a breach?
- Did a security group change accidentally open a path that was then used?
- Is there lateral movement happening inside the VPC?

**Dual destination (CloudWatch + S3) serves two different use cases:**
- CloudWatch → real-time alerting, CloudWatch Logs Insights queries, operational dashboards
- S3 Parquet → long-term retention, cost-efficient storage, Amazon Athena for incident investigation

**KMS encryption on the CloudWatch log group** means even if an attacker gains access to the AWS console, they cannot read flow log data without also having access to the KMS key. This separation of concerns matters for insider threat scenarios.

The **S3 access logging bucket** is a second-order audit capability: it logs who accessed the flow logs bucket itself. This detects attempts to cover tracks by accessing or deleting your audit logs.

---

### 2.6 VPC Endpoints — `endpoints.tf`

**What was provisioned:**

| Endpoint | Type | Cost |
|----------|------|------|
| S3 | Gateway | Free |
| DynamoDB | Gateway | Free |
| EC2 | Interface | ~$7/month per AZ |
| ECR API | Interface | ~$7/month per AZ |
| ECR Docker | Interface | ~$7/month per AZ |
| CloudWatch Logs | Interface | ~$7/month per AZ |
| Secrets Manager | Interface | ~$7/month per AZ |
| SSM | Interface | ~$7/month per AZ |
| SSM Messages | Interface | ~$7/month per AZ |
| EC2 Messages | Interface | ~$7/month per AZ |

All Interface endpoints use the `vpc-endpoints-sg` (HTTPS/443 from VPC CIDR only) and have `private_dns_enabled = true`.

**Why VPC Endpoints are a security control, not just a cost optimization:**

Without VPC Endpoints, when an application in the private subnet calls `secretsmanager.us-east-1.amazonaws.com`, that DNS name resolves to a public IP. The traffic routes: Private Subnet → NAT Gateway → Internet Gateway → Public Internet → AWS Service. The traffic crosses the internet, even though source and destination are both AWS.

With a VPC Endpoint, the DNS name resolves to a private IP inside your VPC. The traffic never leaves the AWS network backbone. This eliminates:

1. **Data exfiltration via DNS/internet path** — an attacker on the network path between your NAT and the AWS service cannot intercept Secrets Manager credentials being fetched
2. **SSRF to non-AWS endpoints** — an attacker exploiting SSRF can reach the IMDS at `169.254.169.254`, but they cannot use the NAT path to reach arbitrary internet URLs if you restrict outbound security group rules
3. **Dependency on NAT for AWS service calls** — data subnet instances that have no NAT route can still call S3, DynamoDB, SSM, and Secrets Manager directly through Gateway/Interface endpoints

**Secrets Manager endpoint is particularly important** — it means the secret retrieval path for database passwords, API keys, and TLS certificates never touches the internet, even from the private subnet.

**SSM endpoint eliminates the need for SSH** to manage instances. Systems Manager Session Manager provides shell access to private subnet instances without any open port 22, without a bastion host, and with full session logging to CloudWatch and S3. The bastion security group exists in this design, but the operational intent is that SSM replaces routine SSH entirely.

---

### 2.7 Routing — `routing.tf`

**What was built:**
- Public route table: `0.0.0.0/0 → IGW` (internet access)
- Private route tables: `0.0.0.0/0 → NAT-GW` (outbound only via NAT)
- Data route table: **No default route** (completely isolated)
- One private route table per AZ (HA configuration)

**The data tier route table having no 0.0.0.0/0 entry is architecturally intentional.** Even if someone creates an IGW attachment or a NAT gateway and tries to route to it, the database subnet has no route for traffic to exit. To give a data subnet internet access, you must explicitly add a route — this creates an audit trail in CloudTrail and requires a deliberate IAM permission.

Per-AZ private route tables (not a single shared one) mean that if NAT Gateway in AZ-1a fails, private instances in AZ-1a stop reaching the internet but private instances in AZ-1b are unaffected and continue using the NAT in AZ-1b.

---

## 3. PIPELINE ANALYSIS

### 3.1 Three-Workflow Architecture

The pipeline is split into three separate workflows with distinct security postures:

```
kics-scan.yml         → Runs on every PR, blocks merge on HIGH/CRITICAL
terraform-deploy.yml  → Plans on PR, applies only on merge to main
terraform-destroy.yml → Manual only, requires typing "DESTROY", requires approval
```

**This separation matters for security.** If all three functions were one workflow, a compromised PR could potentially trigger a destroy. By splitting into separate workflow files and using separate triggers, a pull request can only trigger scanning and planning — never apply or destroy.

---

### 3.2 `kics-scan.yml` — Security Gate

```yaml
# Key security-relevant configuration:
fail-on: HIGH, CRITICAL
output-formats: JSON, HTML, SARIF
upload-sarif: true   # posts to GitHub Security tab
pr-comment: true     # posts findings table on every PR
```

**How it works as a security gate:**

1. A developer opens a PR modifying `.tf` or `.tfvars` files
2. KICS scans the Terraform code against 2,000+ security queries
3. If any HIGH or CRITICAL finding is found → workflow fails → PR cannot be merged (branch protection enforces this)
4. Results appear in three places: PR comment (human-readable table), S3 artifact (JSON for automation), GitHub Security tab (SARIF for security team tracking)
5. Developer fixes the issue, pushes, scan re-runs

**What KICS catches that humans routinely miss:**
- Security groups with `0.0.0.0/0` on sensitive ports
- S3 buckets missing encryption or public access block
- CloudTrail without log file validation
- KMS keys without rotation
- IAM policies with `*` actions or resources
- RDS instances without Multi-AZ
- EBS volumes without encryption
- Missing VPC Flow Logs
- Hardcoded credentials in Terraform variables

The `.kics/kics.config` configuration excludes `.terraform/`, `.git/`, and state files — this prevents false positives from auto-generated Terraform provider code and state metadata which are not user-controlled infrastructure definitions.

`exclude-queries: []` — the empty list is the correct default. No queries are suppressed without a documented reason. Adding a query to the exclusion list should require a security review comment explaining why.

---

### 3.3 `terraform-deploy.yml` — Controlled Deployment

**Security-relevant pipeline controls:**

```yaml
concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false   # never cancel a running deploy
```

Concurrency control prevents two concurrent applies, which would cause Terraform state corruption and could result in infrastructure drift. `cancel-in-progress: false` means a running deployment is never interrupted mid-apply — a partially applied configuration is a known attack surface.

```yaml
# Plan phase runs on PR (safe - read-only)
on:
  pull_request:
    branches: [main, develop]

# Apply phase runs only on merge to main
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

The plan is read-only AWS access — it calls `sts:GetCallerIdentity`, reads resource state, and calls `List*`/`Describe*` APIs. It cannot modify infrastructure. Running the plan on PR lets reviewers see exactly what will change before approving.

The apply only runs on merge to main — this means the PR review process is the approval gate for infrastructure changes. Two reviewers (configured in branch protection) must approve before any infrastructure change takes effect.

```yaml
environment: production  # Requires manual approval in GitHub Environments
```

The `environment: production` block in the apply job means a GitHub Environment protection rule can require a manual approval click from a designated reviewer before `terraform apply` runs. This is a second gate after PR approval.

**The plan output is posted as a PR comment** — this is critical. Without this, reviewers would need to manually run Terraform or trust that the code does what the author says. The comment shows the exact `+`, `-`, and `~` resource changes. A reviewer who sees `- aws_security_group_rule.db_allow_all_inbound` in the plan knows that rule is being deleted and can ask why.

---

### 3.4 `terraform-destroy.yml` — Destruction Controls

This workflow has the strongest safety controls:

```yaml
on:
  workflow_dispatch:
    inputs:
      confirmation:
        description: 'Type "DESTROY" to confirm'
        required: true
      environment:
        type: choice
        options: [dev, staging, prod]
      reason:
        description: 'Reason for destruction'
        required: true
```

**Four-layer protection for destruction:**

1. **Manual trigger only** — no event can trigger this automatically. No push, no PR, no schedule.
2. **Type "DESTROY" exactly** — the validate job checks `inputs.confirmation == 'DESTROY'` (case-sensitive). Typos, "destroy", "yes", or "confirm" all fail. This prevents accidental destruction when running automation against this workflow.
3. **Reason required** — creates an audit trail. The reason field is logged in the workflow run, providing justification for any compliance review.
4. **Environment-specific manual approval** — each environment (dev/staging/prod) can have its own set of required reviewers in GitHub Environments. Production destruction requires the production approval set.

The workflow also **verifies destruction** at the end by running `aws ec2 describe-vpcs` and checking that no VPCs tagged `ManagedBy=Terraform` remain. This provides automated confirmation that the destroy succeeded — important for security incidents where you need to know that a compromised environment has been fully deprovisioned.

---

## 4. KICS INTEGRATION ASSESSMENT

### What KICS is Doing in This Project

KICS (Keeping Infrastructure as Code Secure) is a static analysis tool that evaluates Terraform code before it is ever applied to AWS. It is running against the infrastructure defined in this project's Terraform files.

**Query coverage relevant to this VPC project:**

| Security Domain | KICS Checks |
|----------------|-------------|
| Network Security | SG with 0.0.0.0/0, missing NACLs, unrestricted inbound |
| Encryption | KMS rotation, S3 encryption, CloudWatch log encryption |
| Logging | Flow Logs enabled, CloudTrail config, S3 access logging |
| Access Control | IAM least privilege, public resource exposure |
| High Availability | Multi-AZ RDS, single NAT warnings |
| Tagging | Required tag validation |

### Known Findings the Project Would Produce

Based on the Terraform code, the following KICS findings would likely appear:

**Would PASS (already addressed):**
- ✅ VPC Flow Logs enabled (`flow_logs.tf` fully implemented)
- ✅ S3 server-side encryption enabled on all buckets
- ✅ S3 versioning enabled
- ✅ KMS key rotation enabled (`enable_key_rotation = true`)
- ✅ Security groups use specific ports, not ranges
- ✅ Database subnet has no internet route
- ✅ No hardcoded credentials in any `.tf` file

**Would likely FLAG (findings that still exist):**
- ⚠️ `map_public_ip_on_launch = true` on public subnets — KICS flags this as resources get public IPs automatically. Acceptable for the public tier but worth acknowledging.
- ⚠️ NAT Gateway — KICS may flag single-point configurations depending on `single_nat_gateway` value
- ⚠️ S3 bucket ACL not explicitly set to `private` — newer KICS versions check for explicit `object_ownership = "BucketOwnerEnforced"`
- ⚠️ IAM role trust policy — the VPC Flow Logs role should use a condition to restrict to the specific log group ARN

### The `fail-on: high, critical` Configuration

This is the correct threshold for an automated gate. Setting `fail-on: medium` would generate too many low-signal findings (informational recommendations) that block deployments. Setting `fail-on: critical` only would miss high-severity findings. The HIGH/CRITICAL threshold is the industry standard balance between security rigor and developer velocity.

---

## 5. TERRAFORM CODE QUALITY: SECURITY PERSPECTIVE

### What Was Done Well

**1. Data sources instead of hardcoded values:**
```hcl
data "aws_availability_zones" "available" { state = "available" }
data "aws_caller_identity" "current" {}
```
Using `aws_caller_identity.current.account_id` in resource names and policies prevents copy-paste errors where a resource in account B has a policy referencing account A's ARN.

**2. Count-based multi-AZ with consistent indexing:**
```hcl
availability_zone = data.aws_availability_zones.available.names[count.index]
```
This ensures subnets always align — subnet 0 in AZ 0, subnet 1 in AZ 1. If an AZ is removed or added, the count stays consistent.

**3. Resource dependency chain in NAT:**
```hcl
depends_on = [aws_internet_gateway.main]
```
Elastic IPs for NAT Gateways require the IGW to exist first. Explicit `depends_on` prevents a race condition where Terraform tries to create the EIP association before the IGW is attached.

**4. Conditional NAT and endpoint creation:**
```hcl
count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)) : 0
```
Resources are only created when the feature flag is true. This makes the same Terraform code work for dev (single NAT, no endpoints for cost) and production (HA NAT, all endpoints for security).

**5. S3 lifecycle with Glacier tiering:**
```hcl
transition { days = 30; storage_class = "STANDARD_IA" }
transition { days = 90; storage_class = "GLACIER" }
expiration { days = 365 }
```
Flow logs retention at 365 days satisfies most compliance frameworks (SOC 2, PCI DSS, HIPAA all require 1-year log retention). Lifecycle tiering reduces cost while maintaining availability.

**6. Separate access logging bucket:**
The S3 bucket for flow logs has its own dedicated access log bucket. This is second-order auditing — it creates an immutable record of who accessed the audit logs themselves.

### Areas for Improvement

**1. Remote state backend is commented out:**
```hcl
# backend "s3" {
#   bucket = "your-terraform-state-bucket"
#   ...
# }
```
For staging/production, the state file must be remote. Local state means:
- State is lost if the developer's machine is lost
- No state locking — two engineers running `terraform apply` simultaneously corrupt state
- State contains sensitive values (resource IDs, some ARNs) that should not live in a local file

**2. No state file encryption key specified:**
When the S3 backend is enabled, it should include `kms_key_id` pointing to a dedicated state encryption key — separate from the data encryption keys in the VPC.

**3. `allowed_ssh_cidrs` defaults to empty list:**
Good default, but there is no validation preventing someone from passing `["0.0.0.0/0"]`. A variable validation block should reject that value:
```hcl
validation {
  condition     = !contains(var.allowed_ssh_cidrs, "0.0.0.0/0")
  error_message = "SSH from 0.0.0.0/0 is not permitted."
}
```

**4. No resource deletion protection:**
Critical resources like the VPC, NAT Gateways, and flow log buckets should have `lifecycle { prevent_destroy = true }` in production. This adds a Terraform-level guard against accidental `terraform destroy` of individual resources.

**5. Flow logs S3 bucket MFA delete not enabled:**
For compliance environments, the flow logs S3 bucket should have MFA delete enabled on versioning to prevent evidence tampering:
```hcl
versioning {
  enabled    = true
  mfa_delete = "Enabled"
}
```

---

## 6. OVERALL SECURITY POSTURE ASSESSMENT

### What This Project Gets Right

This is a well-architected network foundation. The three-tier segmentation, dual-layer network controls (SG + NACL), VPC Endpoints for AWS service access, encrypted flow logs with dual destinations, and automated security scanning in the pipeline are all correct decisions. These controls reflect a mature understanding of AWS network security.

The pipeline design — scan before deploy, plan before apply, manual gate before destroy — is the correct operational model for infrastructure that handles sensitive data.

### Security Gaps Not Covered by This Project (By Design)

This project provisions the **network layer** only. It does not provision:

- Application-layer controls (WAF, Shield Advanced, API Gateway)
- Compute security (EC2 IMDSv2 enforcement, GuardDuty for runtime, Inspector for vulnerability scanning)
- Data-layer controls (RDS audit logging, DAM, Secrets Manager for credentials)
- Identity controls (IAM Permission Boundaries, SCP for the account, IAM Access Analyzer)
- Detection and response (GuardDuty, Security Hub, CloudTrail with anomaly detection)

These gaps are expected — this is a VPC project, not a full security platform. They would be addressed by separate Terraform modules layered on top of this foundation.

### Summary Table

| Security Domain | Implemented | Strength |
|----------------|-------------|----------|
| Network Segmentation | ✅ 3-tier isolation | Strong |
| Perimeter Controls | ✅ SG + NACL dual layer | Strong |
| Audit Logging | ✅ VPC Flow Logs (dual dest) | Strong |
| Encryption | ✅ KMS + rotation | Strong |
| Private AWS Access | ✅ VPC Endpoints (9 services) | Strong |
| High Availability | ✅ Multi-AZ NAT + subnets | Strong |
| Pipeline Security | ✅ KICS scan gate | Strong |
| Deployment Controls | ✅ PR approval + concurrency | Strong |
| Destruction Controls | ✅ Manual only + confirmation | Strong |
| Terraform State | ⚠️ Backend commented out | Needs work |
| Variable Validation | ⚠️ No SSH CIDR guard | Needs work |
| Deletion Protection | ⚠️ No lifecycle prevent_destroy | Needs work |
| MFA Delete on Logs | ⚠️ Not configured | Needs work |

---

**Classification:** INTERNAL
**Version:** 1.0
**Scope:** Terraform code, GitHub Actions workflows, KICS configuration
**Excludes:** Threat model documents, scripts directory
