# Data Flow Diagram: Secure VPC Infrastructure

## Overview

This document provides detailed data flow diagrams for the secure VPC architecture, identifying data paths, trust boundaries, and security controls at each layer.

---

## Level 0: Context Diagram

```
┌────────────────────────────────────────────────────────────────────────┐
│                         EXTERNAL ACTORS                                │
└────────────────────────────────────────────────────────────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │            │            │
                    ▼            ▼            ▼
            ┌──────────┐  ┌──────────┐  ┌──────────┐
            │   End    │  │ GitHub   │  │   AWS    │
            │  Users   │  │ Actions  │  │  Admin   │
            └────┬─────┘  └────┬─────┘  └────┬─────┘
                 │             │             │
                 │   HTTPS     │  OIDC/API   │  Console/CLI
                 │             │             │
    ═════════════╪═════════════╪═════════════╪═════════════  TRUST BOUNDARY
                 │             │             │
                 ▼             ▼             ▼
        ┌────────────────────────────────────────────────┐
        │         AWS VPC Infrastructure                 │
        │  ┌──────────────────────────────────────────┐  │
        │  │  • ALB (Public)                          │  │
        │  │  • Application Servers (Private)         │  │
        │  │  • RDS Database (Data)                   │  │
        │  │  • VPC Endpoints                         │  │
        │  │  • NAT Gateways                          │  │
        │  │  • Security Groups                       │  │
        │  │  • Network ACLs                          │  │
        │  └──────────────────────────────────────────┘  │
        └────────────────────────────────────────────────┘
                         │
                         │ Logs & Metrics
                         ▼
                ┌─────────────────┐
                │   CloudWatch    │
                │   VPC Flow Logs │
                │   CloudTrail    │
                └─────────────────┘
```

---

## Level 1: System Data Flow

### 1. User Request Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ USER TRAFFIC FLOW                                                            │
└──────────────────────────────────────────────────────────────────────────────┘

External User
     │
     │ 1. HTTPS Request
     │ Data: HTTP headers, cookies, JSON payload
     │ Sensitive: Auth tokens, PII in request body
     │
     ▼
═══════════════════════════════════════  TRUST BOUNDARY 1: Internet Gateway
     │
     │ Controls:
     │  • TLS 1.2+ termination
     │  • Certificate validation
     │  • DDoS protection (AWS Shield)
     │
     ▼
┌────────────────────┐
│  Application Load  │
│     Balancer       │  PUBLIC SUBNET (10.0.1.0/24, 10.0.2.0/24)
│                    │
│  Security Controls │
│  ✓ TLS termination │
│  ✓ Health checks   │
│  ✓ Access logs     │
│  ✗ WAF (recommended)
└─────────┬──────────┘
          │
          │ 2. HTTP Request (decrypted)
          │ Data: Same as above but decrypted
          │ Protocol: HTTP (internal)
          │
          ▼
═══════════════════════════════════════  TRUST BOUNDARY 2: Private Subnet
          │
          │ Controls:
          │  • Security Group filtering
          │  • Network ACL rules
          │  • No direct internet access
          │
          ▼
┌────────────────────┐
│  Application       │
│  Servers (EC2/ECS) │  PRIVATE SUBNET (10.0.10.0/24, 10.0.20.0/24)
│                    │
│  Security Controls │
│  ✓ IAM instance role
│  ✓ IMDSv2 required │
│  ✓ Security group  │
│  ✓ Systems Manager │
│  ✗ Container scanning
└─────────┬──────────┘
          │
          │ 3. Database Query
          │ Data: SQL queries, credentials (from Secrets Manager)
          │ Sensitive: Customer PII, financial data
          │
          ▼
═══════════════════════════════════════  TRUST BOUNDARY 3: Data Subnet
          │
          │ Controls:
          │  • Database security group (port 3306/5432 only)
          │  • Encryption in transit (TLS)
          │  • No internet access
          │
          ▼
┌────────────────────┐
│  RDS Database      │  DATA SUBNET (10.0.100.0/24, 10.0.200.0/24)
│  (Multi-AZ)        │
│                    │
│  Security Controls │
│  ✓ Encryption at rest (KMS)
│  ✓ Encryption in transit
│  ✓ Automated backups
│  ✓ Private subnet only
│  ✓ Parameter group hardening
└────────────────────┘
          │
          │ 4. Response Data
          │ Data: Query results (PII, business data)
          │
          ▼
    (Returns up the stack)
```

### 2. Outbound Internet Access Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ OUTBOUND TRAFFIC FLOW (Updates, API calls)                                  │
└──────────────────────────────────────────────────────────────────────────────┘

Application Server (Private Subnet)
     │
     │ Needs to access:
     │  • OS updates (yum/apt)
     │  • Docker Hub / ECR
     │  • External APIs
     │
     ▼
═══════════════════════════════════════  Security Group Egress Rule
     │
     │ Controls:
     │  • Restricted outbound ports
     │  • Logged in VPC Flow Logs
     │
     ▼
┌────────────────────┐
│   NAT Gateway      │  PUBLIC SUBNET (10.0.1.0/24, 10.0.2.0/24)
│   (per AZ)         │
│                    │
│  Properties:       │
│  • Static EIP      │
│  • High availability
│  • AWS-managed     │
└─────────┬──────────┘
          │
          │ Outbound traffic
          │ Source: NAT Gateway EIP
          │
          ▼
═══════════════════════════════════════  Internet Gateway
          │
          ▼
      Internet


Alternative: VPC Endpoints (No NAT)
─────────────────────────────────────

Application Server
     │
     │ AWS API calls (S3, DynamoDB, Secrets Manager)
     │
     ▼
┌────────────────────┐
│  VPC Endpoint      │  PRIVATE SUBNET
│  (Interface/Gateway)
│                    │
│  Benefits:         │
│  ✓ No internet path
│  ✓ Lower cost      │
│  ✓ Better security │
│  ✓ Private DNS     │
└─────────┬──────────┘
          │
          │ AWS PrivateLink
          │
          ▼
    AWS Service (S3, DynamoDB, etc.)
```

---

## Level 2: CI/CD Pipeline Data Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ CI/CD DEPLOYMENT FLOW                                                        │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐
│  Developer  │
└──────┬──────┘
       │
       │ 1. Git Push
       │ Data: Code, IaC templates, secrets (encrypted)
       │
       ▼
═══════════════════════════════════════  GitHub Platform
       │
       ▼
┌──────────────────────┐
│  GitHub Repository   │
│                      │
│  Controls:           │
│  ✓ Branch protection │
│  ✓ CODEOWNERS file   │
│  ✓ Required reviews  │
│  ✓ Signed commits    │
└───────┬──────────────┘
        │
        │ 2. Webhook triggers workflow
        │
        ▼
┌──────────────────────┐
│  GitHub Actions      │
│                      │
│  Workflow Steps:     │
│  ├─ Checkout code    │
│  ├─ KICS scan        │  ← Security Control
│  ├─ Terraform plan   │
│  └─ Terraform apply  │
└───────┬──────────────┘
        │
        │ 3. AWS API calls
        │ Authentication: OIDC (no long-lived credentials)
        │
        ▼
═══════════════════════════════════════  AWS Account Boundary
        │
        │ Controls:
        │  • OIDC trust policy
        │  • IAM role assumption
        │  • Least privilege permissions
        │
        ▼
┌──────────────────────┐
│  Terraform State     │
│  (S3 Backend)        │
│                      │
│  Security:           │
│  ✓ Bucket encryption │
│  ✓ Versioning enabled
│  ✓ Access logging    │
│  ✓ Private only      │
└───────┬──────────────┘
        │
        │ 4. Infrastructure changes
        │
        ▼
┌──────────────────────┐
│  VPC Resources       │
│  EC2, RDS, ALB, etc. │
└──────────────────────┘
```

---

## Level 3: Logging and Monitoring Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ LOGGING & MONITORING FLOW                                                    │
└──────────────────────────────────────────────────────────────────────────────┘

VPC Resources
  │   │   │
  │   │   └─ VPC Flow Logs ─────────────────┐
  │   │                                      │
  │   └─ ALB Access Logs ──────────────┐    │
  │                                     │    │
  └─ Application Logs ──────────┐      │    │
                                │      │    │
                                ▼      ▼    ▼
                        ┌──────────────────────────┐
                        │    CloudWatch Logs       │
                        │                          │
                        │  Encryption: KMS         │
                        │  Retention: 30 days      │
                        └────────┬─────────────────┘
                                 │
                                 │ Streamed to
                                 ▼
                        ┌──────────────────────────┐
                        │    S3 Bucket             │
                        │    (Long-term storage)   │
                        │                          │
                        │  ✓ Encryption at rest    │
                        │  ✓ Lifecycle policies    │
                        │  ✓ Access logging        │
                        └────────┬─────────────────┘
                                 │
                                 │ Analyzed by
                                 ▼
                        ┌──────────────────────────┐
                        │    Security Team         │
                        │    (Threat detection)    │
                        └──────────────────────────┘


AWS API Calls
     │
     │ All API activity
     │
     ▼
┌──────────────────────────┐
│     CloudTrail           │
│                          │
│  Captures:               │
│  • Who made the call     │
│  • When                  │
│  • What action           │
│  • Source IP             │
│  • User agent            │
│                          │
│  Controls:               │
│  ✓ Encryption (KMS)      │
│  ✓ Log file validation   │
│  ✓ Multi-region          │
│  ✓ Sent to S3            │
└────────┬─────────────────┘
         │
         │ Alerts on suspicious activity
         ▼
┌──────────────────────────┐
│   CloudWatch Alarms      │
│   • Failed login attempts│
│   • IAM policy changes   │
│   • Root account usage   │
│   • Security group mods  │
└──────────────────────────┘
```

---

## Trust Boundaries Summary

| Boundary | Description | Controls |
|----------|-------------|----------|
| **TB1: Internet → Public Subnet** | External traffic entry point | IGW, ALB, TLS, Shield |
| **TB2: Public → Private Subnet** | DMZ to application tier | Security Groups, NACLs |
| **TB3: Private → Data Subnet** | Application to database | Database SG, TLS, encryption |
| **TB4: GitHub → AWS** | CI/CD deployment boundary | OIDC, IAM roles, least privilege |
| **TB5: VPC → AWS Services** | Access to managed services | VPC Endpoints, IAM policies |

---

## Data Classification

| Data Type | Classification | Location | Protection |
|-----------|---------------|----------|------------|
| Customer PII | CRITICAL | RDS Database | Encryption at rest/transit, access controls |
| Authentication tokens | HIGH | In memory, Secrets Manager | Encryption, rotation, audit logging |
| Application logs | MEDIUM | CloudWatch, S3 | Encryption, retention policy |
| Infrastructure code | HIGH | GitHub, S3 (state) | Access control, encryption, versioning |
| VPC Flow Logs | MEDIUM | CloudWatch, S3 | Encryption, compliance retention |
| Terraform state | HIGH | S3 (encrypted) | Encryption, versioning, access control |

---

## Data Flow Security Controls

### Encryption in Transit
- ✅ **Internet → ALB**: TLS 1.2+
- ✅ **ALB → App**: HTTP (private network, consider mTLS)
- ✅ **App → RDS**: TLS connection required
- ✅ **App → Secrets Manager**: HTTPS (AWS SDK)
- ✅ **GitHub → AWS**: HTTPS (API calls)

### Encryption at Rest
- ✅ **RDS Database**: KMS encryption enabled
- ✅ **S3 Buckets**: Default encryption (KMS)
- ✅ **EBS Volumes**: KMS encryption
- ✅ **CloudWatch Logs**: KMS encryption
- ✅ **Secrets Manager**: KMS encryption (automatic)

### Access Controls
- ✅ **Security Groups**: Stateful firewall at instance level
- ✅ **Network ACLs**: Stateless firewall at subnet level
- ✅ **IAM Policies**: Principal-based access control
- ✅ **Resource Policies**: Resource-based access control (S3, KMS)
- ✅ **VPC Endpoints**: Private AWS service access

---

## Attack Surface Analysis

### External Attack Surface
| Entry Point | Protocol | Protection | Risk |
|-------------|----------|------------|------|
| ALB (Public) | HTTPS:443 | TLS, Shield, SG | MEDIUM |
| SSH (Admin access) | NONE | Systems Manager only | LOW |

### Internal Attack Surface
| Component | Exposure | Protection | Risk |
|-----------|----------|------------|------|
| App → RDS | Private subnet | SG, encryption | LOW |
| App → Secrets Manager | VPC Endpoint | IAM, encryption | LOW |
| App → Internet (outbound) | NAT Gateway | Egress filtering | MEDIUM |

### Management Attack Surface
| Interface | Users | Protection | Risk |
|-----------|-------|------------|------|
| AWS Console | Admins | MFA, IAM | MEDIUM |
| GitHub Actions | CI/CD | OIDC, branch protection | MEDIUM |
| Terraform | Admins | State locking, audit | MEDIUM |

---

**Document Version:** 1.0
**Last Updated:** February 14, 2026
**Reviewer:** DevSecOps Team
