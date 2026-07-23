# IriusRisk-Style Data Flow Diagram

## VPC Infrastructure - Complete Data Flow Visualization

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                                                 │
│  ┌───────────────────────┐                                                                                                     │
│  │   🌐 INTERNET         │                                                                                                     │
│  │   (Untrusted Zone)    │                                                                                                     │
│  │                       │                                                                                                     │
│  │   ┌─────────────┐     │                                                                                                     │
│  │   │     👤      │     │                                                                                                     │
│  │   │   End User  │─────┼────────┐                                                                                            │
│  │   │   Browser   │     │        │                                                                                            │
│  │   └─────────────┘     │        │                                                                                            │
│  │                       │        │                                                                                            │
│  │   ┌─────────────┐     │        │                                                                                            │
│  │   │     🔓      │     │        │                                                                                            │
│  │   │  Attacker   │─────┼────────┤                                                                                            │
│  │   │ (Threat)    │     │        │                                                                                            │
│  │   └─────────────┘     │        │                                                                                            │
│  │                       │        │                                                                                            │
│  └───────────────────────┘        │                                                                                            │
│                                   │                                                                                            │
│  ┌───────────────────────┐        │                                                                                            │
│  │   🔒 VPN Gateway      │        │                                                                                            │
│  │   (Secure Access)     │        │                                                                                            │
│  │                       │        │                                                                                            │
│  │   ┌─────────────┐     │        │                                                                                            │
│  │   │     👨‍💼      │     │        │                                                                                            │
│  │   │   Remote    │─────┼────────┤                                                                                            │
│  │   │  Developer  │     │        │                                                                                            │
│  │   └─────────────┘     │        │                                                                                            │
│  │                       │        │                                                                                            │
│  └───────────────────────┘        │                                                                                            │
│                                   │                                                                                            │
│  ┌───────────────────────┐        │                                                                                            │
│  │   🔥 Firewall         │        │                                                                                            │
│  │   Network Perimeter   │        │                                                                                            │
│  │                       │        │                                                                                            │
│  │   • DDoS Protection   │        │                                                                                            │
│  │   • Threat Intel      │        │                                                                                            │
│  │   • Rate Limiting     │        │                                                                                            │
│  │                       │        │                                                                                            │
│  └───────────────────────┘        │                                                                                            │
│                                   │                                                                                            │
└───────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS (443)
                                    │ Trust Boundary 1
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                  ☁️  AWS CLOUD                                                                  │
│                                                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │  📍 us-east-1a                                        PUBLIC SUBNET (10.0.1.0/24)                                      │   │
│  │  ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════  │   │
│  │                                                                                                                         │   │
│  │         ┌─────────────────┐                                                                                            │   │
│  │         │   🚪 Internet   │                                                                                            │   │
│  │         │     Gateway     │◄───────── ALL INTERNET TRAFFIC                                                             │   │
│  │         │   (IGW-001)     │                                                                                            │   │
│  │         └────────┬────────┘                                                                                            │   │
│  │                  │                                                                                                     │   │
│  │                  │ Route: 0.0.0.0/0                                                                                    │   │
│  │                  ▼                                                                                                     │   │
│  │         ┌─────────────────────────────────────────────┐                                                               │   │
│  │         │        ⚖️  APPLICATION LOAD BALANCER        │                                                               │   │
│  │         │         (production-alb)                    │                                                               │   │
│  │         ├─────────────────────────────────────────────┤                                                               │   │
│  │         │  • Listeners: 80 (→443), 443               │                                                               │   │
│  │         │  • TLS Certificate: ✅ ACM Managed         │                                                               │   │
│  │         │  • Health Checks: ✅ Enabled               │                                                               │   │
│  │         │  • Access Logs: ✅ S3                      │                                                               │   │
│  │         │  • WAF: ❌ NOT ATTACHED (CRITICAL!)        │                                                               │   │
│  │         │                                             │                                                               │   │
│  │         │  🔴 THREATS:                                │                                                               │   │
│  │         │  • DDoS Layer 7 Attack                     │                                                               │   │
│  │         │  • Man-in-the-Middle                       │                                                               │   │
│  │         │  • DNS Hijacking                           │                                                               │   │
│  │         │  • Certificate Theft                       │                                                               │   │
│  │         └──────────────────┬──────────────────────────┘                                                               │   │
│  │                            │                                                                                          │   │
│  │         ┌──────────────────┐                                                                                          │   │
│  │         │  🛡️ Security     │                                                                                          │   │
│  │         │     Group        │ Port 443 from 0.0.0.0/0                                                                  │   │
│  │         │  (alb-sg-001)    │ Port 80 from 0.0.0.0/0                                                                   │   │
│  │         └──────────────────┘                                                                                          │   │
│  │                            │                                                                                          │   │
│  │                            │ HTTP/HTTPS                                                                               │   │
│  │                            │ Trust Boundary 2                                                                         │   │
│  └────────────────────────────┼──────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                ▼                                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │  📍 us-east-1a/1b                                  PRIVATE SUBNET (10.0.2.0/24, 10.0.3.0/24)                          │   │
│  │  ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════  │   │
│  │                                                                                                                         │   │
│  │         ┌────────────────────────────────────────────────────────────────────┐                                         │   │
│  │         │          💻 EC2 / ECS APPLICATION TIER                             │                                         │   │
│  │         │               (app-tier-instances)                                 │                                         │   │
│  │         ├────────────────────────────────────────────────────────────────────┤                                         │   │
│  │         │  Instance Type: t3.medium                                          │                                         │   │
│  │         │  Auto Scaling: ✅ Enabled (2-10 instances)                        │                                         │   │
│  │         │  Container Runtime: ⚠️ Non-root user (partial)                    │                                         │   │
│  │         │  IAM Role: ec2-app-role                                            │                                         │   │
│  │         │  IMDS: ❌ v1 ENABLED (CRITICAL!)                                  │                                         │   │
│  │         │                                                                    │                                         │   │
│  │         │  🔴 THREATS:                                                       │                                         │   │
│  │         │  • SSRF to IMDS (Credential Theft)                                │                                         │   │
│  │         │  • SQL Injection via User Input                                   │                                         │   │
│  │         │  • Code Injection (XSS, Template Injection)                       │                                         │   │
│  │         │  • Container Escape                                               │                                         │   │
│  │         │  • Secrets in Environment Variables                               │                                         │   │
│  │         │  • Resource Exhaustion                                            │                                         │   │
│  │         │                                                                    │                                         │   │
│  │         │  ┌──────────────────────────────────────────┐                     │                                         │   │
│  │         │  │  📦 Application Components:              │                     │                                         │   │
│  │         │  │  • Web Framework (Flask/Django/Express)  │                     │                                         │   │
│  │         │  │  • Business Logic                        │                     │                                         │   │
│  │         │  │  • API Endpoints                         │                     │                                         │   │
│  │         │  │  • Session Management                    │                     │                                         │   │
│  │         │  │  • Database Connection Pool              │                     │                                         │   │
│  │         │  └──────────────────────────────────────────┘                     │                                         │   │
│  │         └─────────────────────┬──────────────────────────────────────────────┘                                         │   │
│  │                               │                                                                                        │   │
│  │         ┌─────────────────────┘                                                                                        │   │
│  │         │                                                                                                              │   │
│  │         │  ┌──────────────────────┐                                                                                   │   │
│  │         │  │  🛡️ Security Group   │                                                                                   │   │
│  │         │  │    (app-sg-001)      │ Port 80/443 from alb-sg-001 only                                                  │   │
│  │         │  │                      │ Port 3306 to db-sg-001                                                            │   │
│  │         │  └──────────────────────┘                                                                                   │   │
│  │         │                                                                                                              │   │
│  │         │  ┌──────────────────────┐                                                                                   │   │
│  │         │  │  🔄 NAT Gateway      │                                                                                   │   │
│  │         │  │   (nat-gw-001)       │ ◄─────── Outbound Internet Access                                                 │   │
│  │         │  │  • Updates/Patches   │          (Package managers, APIs)                                                 │   │
│  │         │  │  • External APIs     │                                                                                   │   │
│  │         │  └──────────────────────┘                                                                                   │   │
│  │         │                                                                                                              │   │
│  │         │ MySQL (3306) - ❌ UNENCRYPTED                                                                                │   │
│  │         │ Trust Boundary 3                                                                                             │   │
│  │         ▼                                                                                                              │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │  📍 us-east-1a/1b                                    DATA SUBNET (10.0.4.0/24, 10.0.5.0/24)                           │   │
│  │  ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════  │   │
│  │                                                                                                                         │   │
│  │         ┌────────────────────────────────────────────────────────────────────┐                                         │   │
│  │         │               🗃️  RDS MYSQL DATABASE                               │                                         │   │
│  │         │              (production-mysql-db)                                 │                                         │   │
│  │         ├────────────────────────────────────────────────────────────────────┤                                         │   │
│  │         │  Instance: db.t3.large (2 vCPU, 8GB RAM)                           │                                         │   │
│  │         │  Engine: MySQL 8.0                                                 │                                         │   │
│  │         │  Multi-AZ: ⚠️ Single AZ (Availability Risk)                        │                                         │   │
│  │         │  Encryption at Rest: ✅ KMS (aws/rds key)                         │                                         │   │
│  │         │  Encryption in Transit: ❌ NOT ENFORCED (CRITICAL!)               │                                         │   │
│  │         │  Backup: ✅ Daily automated snapshots                             │                                         │   │
│  │         │  Backup Encryption: ❌ NOT ENABLED (CRITICAL!)                    │                                         │   │
│  │         │  Audit Logging: ❌ NOT ENABLED (CRITICAL!)                        │                                         │   │
│  │         │                                                                    │                                         │   │
│  │         │  📊 DATA STORED (CROWN JEWEL):                                    │                                         │   │
│  │         │  ┌──────────────────────────────────────────────────┐             │                                         │   │
│  │         │  │  • Customer PII: 150,000 records                 │             │                                         │   │
│  │         │  │    - Names, Emails, Phones                       │             │                                         │   │
│  │         │  │    - Addresses, SSN/Tax IDs                      │             │                                         │   │
│  │         │  │  • Payment Information: 50,000 records           │             │                                         │   │
│  │         │  │    - Tokenized Credit Cards                      │             │                                         │   │
│  │         │  │    - Payment History                             │             │                                         │   │
│  │         │  │  • Business Data: 500,000 records                │             │                                         │   │
│  │         │  │    - Orders, Products, Analytics                 │             │                                         │   │
│  │         │  │                                                  │             │                                         │   │
│  │         │  │  💰 Breach Value: $10M - $30M                    │             │                                         │   │
│  │         │  └──────────────────────────────────────────────────┘             │                                         │   │
│  │         │                                                                    │                                         │   │
│  │         │  🔴 THREATS (CRITICAL ASSET):                                     │                                         │   │
│  │         │  • SQL Injection from Application                                 │                                         │   │
│  │         │  • Data Exfiltration (No DAM)                                     │                                         │   │
│  │         │  • No Audit Trail (Repudiation)                                   │                                         │   │
│  │         │  • Unencrypted Connection                                         │                                         │   │
│  │         │  • Unencrypted Snapshots                                          │                                         │   │
│  │         │  • Credential Theft                                               │                                         │   │
│  │         │  • Privilege Escalation                                           │                                         │   │
│  │         │  • Connection Pool Exhaustion                                     │                                         │   │
│  │         └────────────────────────────────────────────────────────────────────┘                                         │   │
│  │                                                                                                                         │   │
│  │         ┌──────────────────────┐                                                                                       │   │
│  │         │  🛡️ Security Group   │                                                                                       │   │
│  │         │    (db-sg-001)       │ Port 3306 from app-sg-001 ONLY                                                        │   │
│  │         │                      │ No public access ✅                                                                   │   │
│  │         └──────────────────────┘                                                                                       │   │
│  │                   │                                                                                                     │   │
│  │                   │ Backup Flow                                                                                         │   │
│  │                   ▼                                                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                                              🔧 AWS SERVICES (Shared Services)                                          │   │
│  │  ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════  │   │
│  │                                                                                                                         │   │
│  │    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │   │
│  │    │   🔐 KMS     │   │   🔒 Secrets │   │   ⚙️ Param   │   │   📦 S3      │   │   🎫 ACM     │   │  🌐 Route53 │    │   │
│  │    │  (Key Mgmt)  │   │   Manager    │   │    Store     │   │  (Buckets)   │   │  (Cert Mgr)  │   │    (DNS)     │    │   │
│  │    ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤    │   │
│  │    │ • RDS Keys   │   │ ❌ NOT USED  │   │ • App Config │   │ • ALB Logs   │   │ • TLS Certs  │   │ • DNS Zones  │    │   │
│  │    │ • S3 Keys    │   │ (CRITICAL    │   │ • Non-secret │   │ • Backups    │   │ • Auto       │   │ • Health Chk │    │   │
│  │    │ • EBS Keys   │   │  GAP!)       │   │   values     │   │ • Snapshots  │   │   Renewal    │   │              │    │   │
│  │    │              │   │              │   │              │   │              │   │              │   │              │    │   │
│  │    │ ✅ Enabled   │   │ ⚠️ Rec: Use  │   │ ✅ Enabled   │   │ ✅ Encrypted │   │ ✅ Deployed  │   │ ✅ Deployed  │    │   │
│  │    │              │   │   for DB pwd │   │              │   │              │   │              │   │              │    │   │
│  │    └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘    │   │
│  │                                                                                                                         │   │
│  │    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │   │
│  │    │  📊 CloudWtch│   │  📝 CloudTrl │   │  🌊 VPC      │   │  👁️ GuardDty │   │  🛡️ WAF      │   │ 🔰 Shield   │    │   │
│  │    │  (Monitor)   │   │  (Audit)     │   │  Flow Logs   │   │  (Threats)   │   │  (Firewall)  │   │  (DDoS)      │    │   │
│  │    ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤   ├──────────────┤    │   │
│  │    │ • Metrics    │   │ • All API    │   │ ❌ NOT       │   │ ❌ NOT       │   │ ❌ NOT       │   │ ✅ Standard  │    │   │
│  │    │ • Alarms     │   │   Calls      │   │   ENABLED    │   │   ENABLED    │   │   DEPLOYED   │   │   (Free L3/4)│    │   │
│  │    │ • App Logs   │   │ • Logging    │   │ (CRITICAL!)  │   │ (CRITICAL!)  │   │ (CRITICAL!)  │   │ ⚠️ Upgrade  │    │   │
│  │    │              │   │   Enabled    │   │              │   │              │   │              │   │   Rec: Adv   │    │   │
│  │    │ ⚠️ Partial   │   │ ✅ Enabled   │   │ 🔴 BLIND     │   │ 🔴 NO DETECT │   │ 🔴 NO WAF    │   │              │    │   │
│  │    │   Coverage   │   │              │   │   SPOT       │   │              │   │              │   │              │    │   │
│  │    └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘    │   │
│  │                                                                                                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                               🏢 CI/CD & MANAGEMENT ZONE                                                        │
│                                                                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐   │
│  │  🐙 GitHub Platform                                                                                                     │   │
│  │  ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════  │   │
│  │                                                                                                                         │   │
│  │    ┌─────────────────────┐        ┌─────────────────────┐        ┌─────────────────────┐                              │   │
│  │    │  📁 Repository      │        │  ⚙️ GitHub Actions  │        │  🔐 GitHub Secrets  │                              │   │
│  │    │                     │        │                     │        │                     │                              │   │
│  │    │  • Terraform Code   │───────▶│  • KICS Scan        │───────▶│  • AWS OIDC Config  │                              │   │
│  │    │  • App Source       │        │  • terraform plan   │        │  • No Long-lived    │                              │   │
│  │    │  • Workflow Files   │        │  • terraform apply  │        │    Credentials ✅   │                              │   │
│  │    │                     │        │                     │        │                     │                              │   │
│  │    │  ✅ Branch Protect  │        │  🔴 THREATS:        │        │  ⚠️ Secret Masking  │                              │   │
│  │    │  ✅ CODEOWNERS      │        │  • Supply Chain     │        │                     │                              │   │
│  │    │  ✅ MFA Required    │        │  • Compromised      │        │                     │                              │   │
│  │    │                     │        │    Action           │        │                     │                              │   │
│  │    └─────────────────────┘        │  • Malicious Code   │        └─────────────────────┘                              │   │
│  │                                   │  • Workflow Bypass  │                                                              │   │
│  │                                   └─────────────────────┘                                                              │   │
│  │                                            │                                                                            │   │
│  │                                            │ OIDC Authentication                                                        │   │
│  │                                            ▼                                                                            │   │
│  │                                   ┌─────────────────────┐                                                              │   │
│  │                                   │  🔑 AWS IAM OIDC    │                                                              │   │
│  │                                   │     Provider        │                                                              │   │
│  │                                   │                     │                                                              │   │
│  │                                   │  • github-oidc-role │                                                              │   │
│  │                                   │  • Temp Credentials │                                                              │   │
│  │                                   │  • Scoped to Repo   │                                                              │   │
│  │                                   │                     │                                                              │   │
│  │                                   │  ✅ No Static Keys  │                                                              │   │
│  │                                   └─────────────────────┘                                                              │   │
│  │                                                                                                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Legend

```
┌────────────────────────────────────────────────────────────────┐
│                      LEGEND                                    │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Zones:                                                        │
│  ══════                                                        │
│  🌐 Internet Zone        - Untrusted, public internet         │
│  ☁️  AWS Cloud           - AWS infrastructure                 │
│  📍 Public Subnet        - Internet-facing resources          │
│  📍 Private Subnet       - Application tier (isolated)        │
│  📍 Data Subnet          - Database tier (fully isolated)     │
│  🏢 CI/CD Zone           - Deployment pipeline                │
│                                                                │
│  Components:                                                   │
│  ═══════════                                                   │
│  👤 End User             - External user/client               │
│  🔓 Attacker             - Threat actor                       │
│  🚪 Internet Gateway     - AWS IGW                            │
│  ⚖️  Load Balancer       - Application Load Balancer          │
│  💻 EC2/ECS              - Compute instances                  │
│  🗃️  RDS Database        - Relational database                │
│  🛡️  Security Group      - Firewall rules                     │
│  🔄 NAT Gateway          - Network address translation         │
│  🔐 KMS                  - Key Management Service             │
│  🔒 Secrets Manager      - Credential storage                 │
│  📦 S3                   - Object storage                     │
│  🎫 ACM                  - Certificate Manager                │
│  🌐 Route 53             - DNS service                        │
│  📊 CloudWatch           - Monitoring & logging               │
│  📝 CloudTrail           - API audit logs                     │
│  👁️  GuardDuty           - Threat detection                   │
│  🛡️  WAF                 - Web Application Firewall           │
│  🔰 Shield               - DDoS protection                    │
│                                                                │
│  Status Indicators:                                            │
│  ══════════════════                                            │
│  ✅ Deployed/Enabled     - Control implemented                │
│  ❌ Not Deployed/Missing - Critical gap                       │
│  ⚠️  Partial/Warning     - Incomplete implementation          │
│  🔴 Threats              - Security risks identified          │
│                                                                │
│  Data Flows:                                                   │
│  ═══════════                                                   │
│  ──────►                 - Standard data flow                 │
│  ═══════►                - Encrypted connection               │
│  - - - ►                 - Missing/disabled flow              │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Trust Boundaries

```
┌────────────────────────────────────────────────────────────────┐
│                   TRUST BOUNDARY DEFINITIONS                   │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  TB1: Internet ↔ Public Subnet (ALB)                          │
│  ════════════════════════════════════════════════════════════  │
│  Crossing Point: Internet Gateway                             │
│  Protocol: HTTPS (443), HTTP (80 → 443 redirect)             │
│  Controls:                                                     │
│    ✅ TLS 1.2+ encryption                                     │
│    ✅ AWS Shield Standard (DDoS L3/4)                         │
│    ✅ Security Groups                                         │
│    ✅ NACLs                                                   │
│    ❌ WAF (MISSING - CRITICAL)                                │
│    ❌ Rate Limiting (MISSING)                                 │
│  Threats:                                                      │
│    🔴 DDoS Layer 7 attacks                                    │
│    🔴 Web application attacks                                 │
│    🟠 DNS hijacking                                           │
│    🟠 Man-in-the-middle                                       │
│                                                                │
│  TB2: Public Subnet ↔ Private Subnet                          │
│  ════════════════════════════════════════════════════════════  │
│  Crossing Point: ALB → EC2/ECS                                │
│  Protocol: HTTP (Port 80), HTTPS (Port 443)                   │
│  Controls:                                                     │
│    ✅ Security Groups (restricted source)                     │
│    ✅ Private subnet isolation                                │
│    ⚠️  Backend encryption (HTTPS recommended)                 │
│  Threats:                                                      │
│    🔴 SQL injection via application                           │
│    🔴 SSRF to IMDS                                            │
│    🟠 Code injection                                          │
│    🟠 Session hijacking                                       │
│                                                                │
│  TB3: Private Subnet ↔ Data Subnet                            │
│  ════════════════════════════════════════════════════════════  │
│  Crossing Point: EC2/ECS → RDS                                │
│  Protocol: MySQL (Port 3306) - ❌ UNENCRYPTED                 │
│  Controls:                                                     │
│    ✅ Security Groups (app-sg only)                           │
│    ✅ Data subnet isolation                                   │
│    ✅ No public access                                        │
│    ❌ SSL/TLS not enforced (CRITICAL)                         │
│    ❌ No database activity monitoring (CRITICAL)              │
│    ❌ No audit logging (CRITICAL)                             │
│  Threats:                                                      │
│    🔴 SQL injection execution                                 │
│    🔴 Data exfiltration                                       │
│    🔴 Unencrypted data in transit                             │
│    🔴 No audit trail (repudiation)                            │
│    🟠 Privilege escalation                                    │
│    🟠 Connection pool exhaustion                              │
│                                                                │
│  TB4: Private Subnet ↔ AWS Services                           │
│  ════════════════════════════════════════════════════════════  │
│  Crossing Point: EC2/ECS → S3/Secrets/IMDS                    │
│  Protocol: HTTPS (443) + IMDS (169.254.169.254)               │
│  Controls:                                                     │
│    ✅ IAM roles (no long-lived keys)                          │
│    ✅ Encryption in transit                                   │
│    ❌ IMDSv2 not enforced (CRITICAL)                          │
│    ❌ Secrets Manager not used (CRITICAL)                     │
│  Threats:                                                      │
│    🔴 SSRF to IMDSv1 (credential theft)                       │
│    🟠 Secrets in environment variables                        │
│    🟠 Overly permissive IAM roles                             │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Critical Data Flows

```
┌────────────────────────────────────────────────────────────────┐
│              CRITICAL DATA FLOW ANALYSIS                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  FLOW 1: User Request (Customer PII)                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Path: Internet → IGW → ALB → EC2 → RDS                      │
│  Data: Username, password, personal info                      │
│  Classification: 🔴 CRITICAL                                  │
│  Encryption:                                                   │
│    • Internet → ALB: ✅ TLS 1.2+                             │
│    • ALB → EC2: ⚠️  HTTP (unencrypted)                       │
│    • EC2 → RDS: ❌ Cleartext (CRITICAL!)                     │
│  Threats:                                                      │
│    • SQL injection at EC2 level                               │
│    • Network sniffing EC2↔RDS                                 │
│    • No audit trail                                           │
│  Risk Score: 95/100 🔴                                        │
│                                                                │
│  FLOW 2: Database Backups                                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Path: RDS → S3 (Automated Snapshots)                        │
│  Data: Full database dump (all PII)                           │
│  Classification: 🔴 CRITICAL                                  │
│  Encryption:                                                   │
│    • In Transit: ✅ HTTPS                                    │
│    • At Rest (S3): ✅ KMS encrypted                          │
│    • Snapshots: ❌ NOT ENCRYPTED (CRITICAL!)                 │
│  Threats:                                                      │
│    • Unencrypted snapshot exposure                            │
│    • Snapshot sharing misconfiguration                        │
│    • Snapshot deletion                                        │
│  Risk Score: 68/100 🟠                                        │
│                                                                │
│  FLOW 3: Application Secrets                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Path: Parameter Store/Env Vars → EC2 Application            │
│  Data: DB password, API keys, encryption keys                 │
│  Classification: 🔴 CRITICAL                                  │
│  Storage:                                                      │
│    • Database Password: ❌ Environment variable               │
│    • API Keys: ❌ Environment variable                        │
│    • Recommended: ✅ AWS Secrets Manager                     │
│  Threats:                                                      │
│    • Process memory dump                                      │
│    • Container escape → env var access                        │
│    • Secrets in logs                                          │
│  Risk Score: 78/100 🟠                                        │
│                                                                │
│  FLOW 4: IMDS Metadata Access                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Path: EC2 Application → IMDS (169.254.169.254)              │
│  Data: IAM role credentials (temporary)                       │
│  Classification: 🔴 CRITICAL                                  │
│  IMDS Version:                                                 │
│    • Current: ❌ IMDSv1 (Token not required)                 │
│    • Required: ✅ IMDSv2 (Signed token)                      │
│  Threats:                                                      │
│    • SSRF attack → credential theft                           │
│    • Full AWS account compromise                              │
│  Risk Score: 92/100 🔴                                        │
│                                                                │
│  FLOW 5: Outbound Internet (Updates/APIs)                     │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│  Path: EC2 → NAT Gateway → Internet                          │
│  Data: Package downloads, external API calls                  │
│  Classification: 🟡 MEDIUM                                    │
│  Protocol: HTTPS (443)                                         │
│  Threats:                                                      │
│    • Supply chain attacks (malicious packages)                │
│    • Data exfiltration channel                                │
│    • Command & control communication                          │
│  Risk Score: 45/100 🟡                                        │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Risk Summary

```
╔════════════════════════════════════════════════════════════════╗
║              INFRASTRUCTURE RISK SUMMARY                       ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Overall Risk Score: 72/100 🔴 HIGH RISK                      ║
║                                                                ║
║  Critical Components:                                          ║
║  ┌──────────────────────────────────────────────────────────┐ ║
║  │ 1. RDS Database        92/100 🔴 CRITICAL                │ ║
║  │ 2. IMDS Access         92/100 🔴 CRITICAL                │ ║
║  │ 3. Application Tier    78/100 🟠 HIGH                    │ ║
║  │ 4. Load Balancer       85/100 🔴 CRITICAL                │ ║
║  │ 5. Secrets Management  78/100 🟠 HIGH                    │ ║
║  └──────────────────────────────────────────────────────────┘ ║
║                                                                ║
║  Critical Gaps:                                                ║
║  ┌──────────────────────────────────────────────────────────┐ ║
║  │ ❌ No WAF deployment                                     │ ║
║  │ ❌ RDS connections unencrypted                           │ ║
║  │ ❌ No database audit logging                             │ ║
║  │ ❌ IMDSv2 not enforced                                   │ ║
║  │ ❌ Secrets in environment variables                      │ ║
║  │ ❌ No VPC Flow Logs                                      │ ║
║  │ ❌ No GuardDuty                                          │ ║
║  │ ❌ Unencrypted RDS snapshots                             │ ║
║  └──────────────────────────────────────────────────────────┘ ║
║                                                                ║
║  Potential Breach Impact: $18M - $63M                         ║
║  Security Investment Needed: $90K/year                        ║
║  ROI: 6,300% - 22,300%                                        ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

---

**Document Classification:** CONFIDENTIAL
**Version:** 2.0 (IriusRisk Visual Edition)
**Last Updated:** February 14, 2026
**Tool:** IriusRisk-style Data Flow Diagram
**Owner:** DevSecOps Team
