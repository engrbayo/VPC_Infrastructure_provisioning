# STRIDE Threat Modeling Reference Guide

## Overview

STRIDE is a threat modeling framework developed by Microsoft. It provides a systematic way to identify security threats by categorizing them into six types.

---

## The STRIDE Model

```
┌──────────────────────────────────────────────────────────────────┐
│                     STRIDE CATEGORIES                            │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  S - SPOOFING IDENTITY                                           │
│  T - TAMPERING WITH DATA                                         │
│  R - REPUDIATION                                                 │
│  I - INFORMATION DISCLOSURE                                      │
│  D - DENIAL OF SERVICE                                           │
│  E - ELEVATION OF PRIVILEGE                                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## S - SPOOFING IDENTITY

### Definition
Pretending to be something or someone other than yourself.

### Examples in Cloud Infrastructure
- **IAM Role Assumption:** Attacker assumes an IAM role using stolen credentials
- **SSRF to IMDS:** Application vulnerability allows access to instance metadata
- **Certificate Forgery:** Using fake or stolen TLS certificates
- **IP Spoofing:** Forging source IP address in packets
- **DNS Spoofing:** Redirecting traffic via poisoned DNS records

### Common Attack Vectors
```
User Credential Theft
├─ Phishing emails
├─ Keyloggers
├─ Session hijacking
└─ Credential stuffing

Service Impersonation
├─ Man-in-the-middle attacks
├─ Rogue access points
└─ Fake services in VPC
```

### Mitigations
✅ **Authentication:**
- Multi-factor authentication (MFA)
- Strong password policies
- Certificate-based authentication
- IAM roles instead of access keys

✅ **AWS-Specific:**
- IMDSv2 (requires signed token)
- AWS Certificate Manager for TLS
- VPC endpoint policies
- CloudTrail for API call attribution

✅ **Network:**
- TLS mutual authentication
- VPC security groups
- NACLs to prevent IP spoofing

---

## T - TAMPERING WITH DATA

### Definition
Modifying data or code in an unauthorized manner.

### Examples in Cloud Infrastructure
- **Man-in-the-Middle:** Intercepting and modifying traffic between components
- **SQL Injection:** Modifying database data via malicious queries
- **Terraform State Tampering:** Directly editing state file in S3
- **Code Injection:** Injecting malicious code into CI/CD pipeline
- **Configuration Changes:** Unauthorized modification of security groups

### Common Attack Vectors
```
Data in Transit
├─ MITM attacks
├─ Packet injection
└─ SSL/TLS downgrade

Data at Rest
├─ Direct S3 object modification
├─ Database record changes
└─ EBS volume tampering

Infrastructure as Code
├─ Malicious commits
├─ Workflow file modifications
└─ State file tampering
```

### Mitigations
✅ **Encryption:**
- TLS for data in transit
- KMS encryption for data at rest
- Signed commits in Git
- Code signing for containers

✅ **Integrity:**
- S3 object versioning
- DynamoDB streams for audit
- CloudTrail log file validation
- EBS snapshot encryption

✅ **Access Control:**
- IAM policies with least privilege
- S3 bucket policies
- Resource tagging and policies
- MFA delete on critical resources

---

## R - REPUDIATION

### Definition
Denying that an action occurred without any way to prove otherwise.

### Examples in Cloud Infrastructure
- **No Audit Logs:** User denies making API call (no CloudTrail)
- **Log Deletion:** Attacker deletes evidence after compromise
- **Unsigned Commits:** Developer denies writing malicious code
- **Missing Database Logs:** Cannot prove unauthorized data access

### Common Attack Vectors
```
Log Manipulation
├─ Deleting CloudWatch log streams
├─ Modifying S3 log files
└─ Disabling CloudTrail

Lack of Logging
├─ Application doesn't log user actions
├─ Database audit logs disabled
└─ VPC Flow Logs not enabled
```

### Mitigations
✅ **Logging:**
- CloudTrail (all API calls)
- VPC Flow Logs (network traffic)
- ALB/NLB access logs
- Application audit logs
- RDS audit logging

✅ **Log Protection:**
- S3 Object Lock (immutable logs)
- Log file validation (CloudTrail)
- Cross-account log delivery
- Log encryption with KMS

✅ **Code Integrity:**
- Signed Git commits (GPG/SSH)
- Code review trails
- CODEOWNERS file
- Pull request history

---

## I - INFORMATION DISCLOSURE

### Definition
Exposing information to users who are not authorized to see it.

### Examples in Cloud Infrastructure
- **Public S3 Buckets:** Sensitive data accessible to internet
- **SSRF Attacks:** Accessing IMDS to retrieve IAM credentials
- **Exposed Secrets:** Credentials in logs, environment variables, or code
- **Verbose Error Messages:** Stack traces revealing internal architecture
- **Unencrypted Data:** Sensitive data stored in plaintext

### Common Attack Vectors
```
Storage Exposure
├─ Public S3 buckets
├─ Public EBS snapshots
├─ Unencrypted RDS snapshots
└─ Public AMIs

Application Vulnerabilities
├─ SQL injection (data extraction)
├─ SSRF to IMDS
├─ Path traversal
└─ XXE attacks

Accidental Leaks
├─ Secrets in Git commits
├─ Credentials in logs
├─ PII in ALB access logs
└─ Debug endpoints in production
```

### Mitigations
✅ **Access Control:**
- S3 Block Public Access
- Security group least privilege
- IAM policies (no public read)
- VPC endpoints (private AWS access)

✅ **Encryption:**
- Encryption at rest (KMS)
- Encryption in transit (TLS)
- Secrets Manager for credentials
- Field-level encryption

✅ **Application Security:**
- Input validation (prevent SSRF)
- Custom error pages (no stack traces)
- Log scrubbing (remove PII/secrets)
- IMDSv2 (prevent simple SSRF)

---

## D - DENIAL OF SERVICE

### Definition
Making a system or service unavailable to legitimate users.

### Examples in Cloud Infrastructure
- **DDoS Attacks:** Overwhelming ALB with traffic
- **Resource Exhaustion:** CPU/memory bomb crashes instances
- **API Rate Limiting:** Exhausting AWS API quotas
- **Storage Exhaustion:** Filling disk space on RDS
- **Deleting Resources:** Terminating critical infrastructure

### Common Attack Vectors
```
Network-Based
├─ SYN flood (Layer 3/4)
├─ HTTP flood (Layer 7)
├─ Slowloris attack
└─ DNS amplification

Application-Based
├─ CPU exhaustion (crypto mining)
├─ Memory exhaustion (ZIP bomb)
├─ Regex DoS (ReDoS)
└─ Database connection exhaustion

Infrastructure-Based
├─ Delete VPC via API
├─ Terminate all instances
├─ Delete RDS snapshots
└─ Revoke security group rules
```

### Mitigations
✅ **Network Protection:**
- AWS Shield Standard (free DDoS protection)
- AWS Shield Advanced (enhanced protection)
- AWS WAF with rate limiting rules
- CloudFront for DDoS absorption

✅ **Scalability:**
- Auto Scaling groups
- Multi-AZ deployment
- ALB automatic scaling
- RDS Read Replicas

✅ **Resource Protection:**
- IAM policies (prevent deletion)
- CloudWatch alarms
- Service quotas and limits
- Health checks and auto-recovery

---

## E - ELEVATION OF PRIVILEGE

### Definition
Gaining capabilities without proper authorization (e.g., user becomes admin).

### Examples in Cloud Infrastructure
- **IAM Privilege Escalation:** Exploiting PassRole to attach admin policy
- **Container Escape:** Breaking out of container to access host
- **SSRF to IMDS:** Gaining IAM role credentials via application vulnerability
- **Kernel Exploit:** Exploiting OS vulnerability to gain root access
- **SQL Injection:** Using UNION to escalate database privileges

### Common Attack Vectors
```
IAM-Based
├─ iam:PassRole exploitation
├─ iam:* wildcard policies
├─ Assume role without proper validation
└─ Attach overly permissive policies

Application-Based
├─ SSRF to IMDS (get temporary creds)
├─ Container escape to host
├─ SQL injection (UNION-based escalation)
└─ Code injection in Lambda

System-Based
├─ Kernel exploits (privilege escalation to root)
├─ sudo misconfiguration
├─ Unpatched vulnerabilities
└─ Insecure deserialization
```

### Mitigations
✅ **IAM Best Practices:**
- Least privilege policies
- Permission boundaries
- Service Control Policies (SCPs)
- No wildcard (*) permissions

✅ **Runtime Protection:**
- IMDSv2 required
- Containers run as non-root
- AppArmor/SELinux profiles
- AWS GuardDuty for anomaly detection

✅ **Patching & Hardening:**
- Regular OS patching
- Immutable infrastructure
- CIS benchmarks
- Runtime security monitoring

---

## STRIDE Application by Component Type

### Data Stores (S3, RDS, DynamoDB)
```
S - Unauthorized access using stolen credentials
T - Data modification via SQL injection or direct API
R - No audit logs of who accessed what
I - Public buckets, unencrypted data, snapshot leaks
D - Delete bucket/table, storage exhaustion
E - Gain admin access via IAM misconfiguration
```

### Processes (EC2, Lambda, Containers)
```
S - Process impersonation via SSRF to IMDS
T - Code injection, malicious package dependencies
R - No process execution logs
I - Secrets in environment variables, memory dumps
D - CPU/memory exhaustion, termination
E - Container escape, privilege escalation to root
```

### Data Flows (Network Traffic)
```
S - IP spoofing, session hijacking
T - Man-in-the-middle modification
R - No VPC Flow Logs
I - Unencrypted traffic (no TLS)
D - Network flooding, route hijacking
E - Traffic interception leads to credential theft
```

### External Entities (Users, Services)
```
S - Account takeover, fake identity
T - Malicious input injection
R - User denies action (no audit trail)
I - Exposed credentials, leaked tokens
D - Account lockout, API abuse
E - Social engineering to gain admin access
```

---

## Threat Modeling Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                  STRIDE THREAT MODELING PROCESS                 │
└─────────────────────────────────────────────────────────────────┘

Step 1: DIAGRAM THE SYSTEM
├─ Identify components (ALB, EC2, RDS, etc.)
├─ Map data flows between components
└─ Mark trust boundaries (Internet → VPC, etc.)

Step 2: IDENTIFY THREATS (per component)
├─ For each component, ask:
│  ├─ S: Can someone pretend to be this component?
│  ├─ T: Can data be tampered with?
│  ├─ R: Can actions be denied?
│  ├─ I: Can secrets be disclosed?
│  ├─ D: Can this be made unavailable?
│  └─ E: Can privileges be escalated?
└─ Document threats in a table

Step 3: MITIGATE THREATS
├─ Identify existing controls
├─ Recommend additional mitigations
├─ Prioritize by risk (Likelihood × Impact)
└─ Assign owners and timelines

Step 4: VALIDATE
├─ Test mitigations (pentesting, scanning)
├─ Review threat model quarterly
└─ Update after architecture changes
```

---

## STRIDE to Security Properties Mapping

| STRIDE Threat | Violated Property | Desired Property |
|---------------|-------------------|------------------|
| Spoofing | Authentication | Authenticated identity |
| Tampering | Integrity | Data integrity |
| Repudiation | Non-repudiation | Audit trail exists |
| Information Disclosure | Confidentiality | Data confidentiality |
| Denial of Service | Availability | System availability |
| Elevation of Privilege | Authorization | Authorized access only |

---

## Common Pitfalls to Avoid

❌ **Don't:**
- Focus only on external threats (insider threats are real)
- Skip components because they "seem secure"
- Treat STRIDE as a checklist (it's a thinking tool)
- Perform threat modeling once and never update it
- Ignore threats because "we haven't been attacked before"

✅ **Do:**
- Consider all threat actors (external, insider, supply chain)
- Analyze every component and data flow
- Use STRIDE to brainstorm creatively
- Update threat model after architecture changes
- Prioritize threats by realistic risk, not theoretical

---

**Document Classification:** INTERNAL
**Version:** 1.0
**Last Updated:** February 14, 2026
