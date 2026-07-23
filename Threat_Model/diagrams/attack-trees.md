# Attack Trees

## Overview

Attack trees provide a structured way to model how an attacker might achieve a specific goal. Each tree shows the primary objective at the root, with various attack paths branching below.

---

## Attack Tree 1: Data Exfiltration from RDS Database

```
                    ┌─────────────────────────────────┐
                    │ GOAL: Exfiltrate Customer Data │
                    │       from RDS Database         │
                    └────────────────┬────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
    ┌───────────────┐        ┌───────────────┐      ┌───────────────┐
    │ Compromise    │        │  SQL          │      │  Insider      │
    │ Application   │        │  Injection    │      │  Threat       │
    │ Server        │        │               │      │               │
    └───────┬───────┘        └───────┬───────┘      └───────┬───────┘
            │                        │                      │
    ┌───────┴───────┐        ┌───────┴───────┐              │
    │               │        │               │              │
    ▼               ▼        ▼               ▼              ▼
┌────────┐     ┌────────┐ ┌────────┐   ┌────────┐   ┌──────────┐
│  SSRF  │     │ Stolen │ │ Input  │   │ Blind  │   │ Database │
│   to   │     │  SSH   │ │  Not   │   │  SQLi  │   │  Admin   │
│ IMDSv2 │     │  Key   │ │Sanitized   │        │   │  Access  │
└───┬────┘     └───┬────┘ └───┬────┘   └───┬────┘   └────┬─────┘
    │              │          │            │             │
    │              │          │            │             │
    ▼              ▼          ▼            ▼             ▼
┌────────────────────────────────────────────────────────────┐
│                     SUCCESS PATH                           │
│  1. Gain database credentials                              │
│  2. Connect to RDS (port 3306/5432)                       │
│  3. Execute SELECT query to extract PII                   │
│  4. Exfiltrate data via DNS tunneling or HTTPS POST       │
└────────────────────────────────────────────────────────────┘
```

### Attack Path Analysis

| Path | Attack Steps | Difficulty | Detection | Mitigations |
|------|--------------|------------|-----------|-------------|
| **Path 1: SSRF** | SSRF → IMDSv2 → Credentials → DB Access | HARD | ✅ GuardDuty | ✅ IMDSv2 + Input validation |
| **Path 2: SSH Key Theft** | Phish developer → Steal key → SSH to server → DB access | MEDIUM | ✅ CloudTrail | ✅ No SSH (use SSM) |
| **Path 3: SQL Injection** | Find SQLi vuln → Extract data directly | MEDIUM | ⚠️ WAF (if enabled) | ⚠️ Input validation + SAST |
| **Path 4: Blind SQLi** | Automated tools → Time-based extraction | HARD | ⚠️ DAM (if deployed) | ⚠️ WAF + prepared statements |
| **Path 5: Insider** | Authorized access → Export data | EASY | ✅ Audit logs | ✅ RBAC + DLP |

### Risk Rating by Path

```
Path         Likelihood    Impact      Risk      Priority
────────────────────────────────────────────────────────────
SSRF         MEDIUM        CRITICAL    HIGH      P1
SSH Theft    LOW           HIGH        MEDIUM    P2
SQL Inject   MEDIUM        CRITICAL    HIGH      P1
Blind SQLi   LOW           CRITICAL    MEDIUM    P2
Insider      LOW           CRITICAL    MEDIUM    P2
```

---

## Attack Tree 2: Infrastructure Takeover via Compromised CI/CD

```
                    ┌──────────────────────────────────┐
                    │ GOAL: Take Control of AWS        │
                    │       Production Infrastructure  │
                    └────────────────┬─────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
    ┌───────────────┐        ┌───────────────┐      ┌───────────────┐
    │ Compromise    │        │  Steal AWS    │      │  Manipulate   │
    │ GitHub        │        │  Credentials  │      │  Terraform    │
    │ Repository    │        │               │      │  State        │
    └───────┬───────┘        └───────┬───────┘      └───────┬───────┘
            │                        │                      │
    ┌───────┴───────┐        ┌───────┴───────┐              │
    │               │        │               │              │
    ▼               ▼        ▼               ▼              ▼
┌────────┐     ┌────────┐ ┌────────┐   ┌────────┐   ┌──────────┐
│ Phish  │     │Compromise│ Extract│   │ IMDS   │   │ Modify   │
│Developer     │ GitHub  │ from   │   │ SSRF   │   │ S3 State │
│        │     │ Action  │ Logs   │   │        │   │ File     │
└───┬────┘     └───┬────┘ └───┬────┘   └───┬────┘   └────┬─────┘
    │              │          │            │             │
    │              │          │            │             │
    ▼              ▼          ▼            ▼             ▼
┌────────────────────────────────────────────────────────────┐
│                     SUCCESS PATH                           │
│  1. Gain write access to main branch                      │
│  2. Modify Terraform code to create backdoor IAM user     │
│  3. Workflow runs and deploys malicious infrastructure    │
│  4. Attacker uses backdoor for persistent access          │
└────────────────────────────────────────────────────────────┘
```

### Attack Path Analysis

| Path | Attack Steps | Difficulty | Detection | Mitigations |
|------|--------------|------------|-----------|-------------|
| **Path 1: Phish Developer** | Phish → Compromise account → Merge malicious code | MEDIUM | ✅ MFA + PR review | ✅ MFA + code review |
| **Path 2: Malicious Action** | Create fake action → Developer uses it → Backdoor | HARD | ⚠️ Action auditing | ⚠️ Pin to SHA |
| **Path 3: Extract from Logs** | Access workflow logs → Find leaked secret | EASY | ✅ Secret masking | ✅ No secrets in logs |
| **Path 4: IMDS SSRF** | SSRF in app → IMDS → Credentials → AWS access | MEDIUM | ✅ GuardDuty | ✅ IMDSv2 |
| **Path 5: Modify State** | Compromise S3 access → Edit state → Drift exploit | HARD | ✅ CloudTrail | ✅ State locking + versioning |

---

## Attack Tree 3: Denial of Service on Production VPC

```
                    ┌──────────────────────────────────┐
                    │ GOAL: Make Production VPC        │
                    │       Unavailable                │
                    └────────────────┬─────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
    ┌───────────────┐        ┌───────────────┐      ┌───────────────┐
    │ DDoS Attack   │        │  Resource     │      │  Delete       │
    │ on ALB        │        │  Exhaustion   │      │  Critical     │
    │               │        │               │      │  Resources    │
    └───────┬───────┘        └───────┬───────┘      └───────┬───────┘
            │                        │                      │
    ┌───────┴───────┐        ┌───────┴───────┐              │
    │               │        │               │              │
    ▼               ▼        ▼               ▼              ▼
┌────────┐     ┌────────┐ ┌────────┐   ┌────────┐   ┌──────────┐
│ Layer 3│     │ Layer 7│ │ Crypto │   │  CPU   │   │ Delete   │
│ Flood  │     │ Flood  │ │ Mining │   │  Bomb  │   │ VPC via  │
│        │     │        │ │ in App │   │        │   │ AWS API  │
└───┬────┘     └───┬────┘ └───┬────┘   └───┬────┘   └────┬─────┘
    │              │          │            │             │
    │              │          │            │             │
    ▼              ▼          ▼            ▼             ▼
┌────────────────────────────────────────────────────────────┐
│                   IMPACT OUTCOME                           │
│  • Service unavailable to legitimate users                │
│  • Revenue loss during downtime                           │
│  • Reputation damage                                      │
│  • SLA violations                                         │
└────────────────────────────────────────────────────────────┘
```

### Attack Path Analysis

| Path | Attack Steps | Difficulty | Detection | Mitigations |
|------|--------------|------------|-----------|-------------|
| **Path 1: L3 DDoS** | Botnet → SYN flood → Network saturation | MEDIUM | ✅ AWS Shield | ✅ Shield Standard |
| **Path 2: L7 DDoS** | HTTP flood → Exhaust ALB capacity | MEDIUM | ⚠️ WAF (if enabled) | ⚠️ WAF rate limiting |
| **Path 3: Crypto Mining** | Exploit app vuln → Mine crypto → CPU exhaustion | MEDIUM | ✅ CloudWatch CPU alarm | ✅ Auto-scaling |
| **Path 4: CPU Bomb** | ZIP bomb or regex DoS → App crash | HARD | ✅ Health checks | ⚠️ Input validation |
| **Path 5: Delete VPC** | Steal AWS creds → Delete resources | LOW | ✅ CloudTrail | ✅ IAM least privilege |

---

## Attack Tree 4: Privilege Escalation to AWS Admin

```
                    ┌──────────────────────────────────┐
                    │ GOAL: Gain Full AWS Admin Access│
                    │      (Administrator Role)        │
                    └────────────────┬─────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
    ┌───────────────┐        ┌───────────────┐      ┌───────────────┐
    │ Exploit IAM   │        │  Compromise   │      │  Social       │
    │ Misconfiguration      │  Root Account │      │  Engineering  │
    │               │        │               │      │               │
    └───────┬───────┘        └───────┬───────┘      └───────┬───────┘
            │                        │                      │
    ┌───────┴───────┐        ┌───────┴───────┐              │
    │               │        │               │              │
    ▼               ▼        ▼               ▼              ▼
┌────────┐     ┌────────┐ ┌────────┐   ┌────────┐   ┌──────────┐
│ iam:*  │     │ Pass   │ │ Root   │   │ Leaked │   │ Convince │
│ Policy │     │ Role   │ │ Keys   │   │ MFA    │   │ Admin to │
│        │     │ Attached   │ Found  │   │ Seed   │   │Run Command
└───┬────┘     └───┬────┘ └───┬────┘   └───┬────┘   └────┬─────┘
    │              │          │            │             │
    │              │          │            │             │
    ▼              ▼          ▼            ▼             ▼
┌────────────────────────────────────────────────────────────┐
│                 ESCALATION SUCCESS                         │
│  1. Attacker assumes role with admin permissions          │
│  2. Creates backdoor IAM user                             │
│  3. Adds long-lived access keys                           │
│  4. Maintains persistent administrative access            │
└────────────────────────────────────────────────────────────┘
```

### Attack Path Analysis

| Path | Attack Steps | Difficulty | Detection | Mitigations |
|------|--------------|------------|-----------|-------------|
| **Path 1: IAM iam:\*** | Find overly permissive policy → Escalate | LOW | ✅ IAM Access Analyzer | ✅ Least privilege |
| **Path 2: PassRole** | Exploit PassRole → Attach admin policy | MEDIUM | ✅ CloudTrail | ✅ Boundary policies |
| **Path 3: Root Keys** | Find root access keys in code → Use them | LOW | ✅ Secret scanning | ✅ Never use root keys |
| **Path 4: MFA Seed Leak** | Steal MFA seed → Bypass MFA | HARD | ✅ Hardware MFA | ✅ Use YubiKey |
| **Path 5: Social Engineering** | Convince admin → Run malicious command | MEDIUM | ⚠️ Security training | ⚠️ Awareness training |

---

## Defense Strategies by Attack Type

### Against Data Exfiltration
```
PREVENTION:
├─ Input validation (prevent SQLi)
├─ WAF with SQL injection rules
├─ Least privilege database users
└─ Network segmentation (data subnet isolation)

DETECTION:
├─ Database activity monitoring (DAM)
├─ VPC Flow Logs analysis
├─ CloudWatch alarms on unusual query patterns
└─ Data Loss Prevention (DLP) tools

RESPONSE:
├─ Automated security group updates (block attacker IP)
├─ Incident response runbook
├─ Database connection kill switch
└─ Forensic analysis of query logs
```

### Against Infrastructure Takeover
```
PREVENTION:
├─ MFA for all privileged accounts
├─ Branch protection rules
├─ Code review requirements
├─ OIDC (no long-lived credentials)
└─ Terraform state locking

DETECTION:
├─ GitHub audit logs
├─ CloudTrail monitoring
├─ Alerts on workflow file changes
└─ IAM policy change notifications

RESPONSE:
├─ Revoke compromised credentials
├─ Rollback malicious infrastructure changes
├─ Force MFA re-enrollment
└─ Incident review and lessons learned
```

### Against Denial of Service
```
PREVENTION:
├─ AWS Shield Standard (free)
├─ AWS WAF with rate limiting
├─ Auto-scaling groups
└─ Multi-AZ deployment

DETECTION:
├─ CloudWatch alarms on 5XX errors
├─ High request rate alerts
├─ CPU/memory utilization monitoring
└─ Health check failures

RESPONSE:
├─ Scale up resources automatically
├─ Block malicious IPs via WAF
├─ Engage AWS Support (Shield Advanced)
└─ Implement emergency rate limiting
```

---

## Attack Complexity Matrix

| Attack Type | Technical Skill | Resources | Time | Detection Difficulty |
|-------------|----------------|-----------|------|---------------------|
| SQL Injection | MEDIUM | LOW | HOURS | MEDIUM |
| SSRF to IMDS | MEDIUM | LOW | HOURS | HARD |
| DDoS (Layer 3) | LOW | HIGH | MINUTES | EASY |
| DDoS (Layer 7) | MEDIUM | MEDIUM | MINUTES | MEDIUM |
| Phishing | LOW | LOW | DAYS | HARD |
| Supply Chain | HIGH | HIGH | MONTHS | VERY HARD |
| Insider Threat | LOW | NONE | MINUTES | HARD |
| IAM Privilege Escalation | MEDIUM | LOW | HOURS | MEDIUM |

---

**Document Classification:** CONFIDENTIAL
**Version:** 1.0
**Last Updated:** February 14, 2026
