# VPC Infrastructure Threat Model

## 1. SYSTEM OVERVIEW

### What is Being Built?
A secure, multi-tier AWS VPC infrastructure designed to host web applications with the following characteristics:

- **Architecture:** 3-tier (Public, Private, Data subnets)
- **High Availability:** Multi-AZ deployment (us-east-1a, us-east-1b)
- **Scalability:** Auto-scaling capable, load balanced
- **Security:** Defense in depth with multiple security layers
- **Compliance:** Logging and monitoring for audit requirements

### What Data Does It Handle?
| Data Type | Sensitivity | Volume | Retention |
|-----------|-------------|--------|-----------|
| Customer PII | CRITICAL | High | 7 years |
| Authentication credentials | CRITICAL | Medium | Until rotation |
| Application logs | MEDIUM | High | 30 days |
| Infrastructure metrics | LOW | High | 90 days |
| Audit trails | HIGH | Medium | 7 years |

### Who Are the Users?
- **End Users:** Internet-facing customers accessing web applications
- **Administrators:** DevOps/SecOps team managing infrastructure
- **Developers:** Deploying code via CI/CD pipeline
- **Security Team:** Monitoring and incident response

---

## 2. ARCHITECTURE DIAGRAM

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  VPC: 10.0.0.0/16 (secure-vpc)                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                        │ │
│  │  ┌───────────────────────┐         ┌───────────────────────┐          │ │
│  │  │  PUBLIC SUBNET (AZ-A) │         │  PUBLIC SUBNET (AZ-B) │          │ │
│  │  │  10.0.1.0/24          │         │  10.0.2.0/24          │          │ │
│  │  │                       │         │                       │          │ │
│  │  │  ┌─────┐  ┌────────┐ │         │  ┌─────┐  ┌────────┐  │          │ │
│  │  │  │ ALB │  │ NAT GW │ │         │  │ ALB │  │ NAT GW │  │          │ │
│  │  │  └──┬──┘  └───┬────┘ │         │  └──┬──┘  └───┬────┘  │          │ │
│  │  └─────┼─────────┼──────┘         └─────┼─────────┼───────┘          │ │
│  │        │         │                      │         │                  │ │
│  │  ══════╪═════════╪══════════════════════╪═════════╪═════  TB1        │ │
│  │        │         │                      │         │                  │ │
│  │  ┌─────▼─────────┼──────┐         ┌─────▼─────────┼───────┐          │ │
│  │  │ PRIVATE (AZ-A)│      │         │ PRIVATE (AZ-B)│       │          │ │
│  │  │ 10.0.10.0/24  │      │         │ 10.0.20.0/24  │       │          │ │
│  │  │               │      │         │               │       │          │ │
│  │  │  ┌──────────┐ │      │         │  ┌──────────┐ │       │          │ │
│  │  │  │ EC2/ECS  │◄┼──────┼─────────┼─▶│ EC2/ECS  │ │       │          │ │
│  │  │  └────┬─────┘ │      │         │  └────┬─────┘ │       │          │ │
│  │  └───────┼───────┘      │         └───────┼───────┘       │          │ │
│  │          │              │                 │               │          │ │
│  │  ════════╪══════════════╪═════════════════╪═══════  TB2   │          │ │
│  │          │              │                 │               │          │ │
│  │  ┌───────▼──────┐       │         ┌───────▼──────┐        │          │ │
│  │  │ DATA (AZ-A)  │       │         │ DATA (AZ-B)  │        │          │ │
│  │  │ 10.0.100.0/24│       │         │ 10.0.200.0/24│        │          │ │
│  │  │              │       │         │              │        │          │ │
│  │  │  ┌────────┐  │       │         │  ┌────────┐  │        │          │ │
│  │  │  │  RDS   │◄─┼───────┼─────────┼─▶│  RDS   │  │        │          │ │
│  │  │  │Primary │  │       │         │  │Standby │  │        │          │ │
│  │  │  └────────┘  │       │         │  └────────┘  │        │          │ │
│  │  └──────────────┘       │         └──────────────┘        │          │ │
│  │                         │                                 │          │ │
│  │  ┌──────────────────────▼─────────────────────────────┐   │          │ │
│  │  │ VPC ENDPOINTS                                      │   │          │ │
│  │  │ • S3 (Gateway)                                     │   │          │ │
│  │  │ • Secrets Manager (Interface)                      │   │          │ │
│  │  │ • EC2 API (Interface)                              │   │          │ │
│  │  │ • SSM (Interface)                                  │   │          │ │
│  │  └────────────────────────────────────────────────────┘   │          │ │
│  │                                                            │          │ │
│  └────────────────────────────────────────────────────────────┘          │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────┐          │
│  │ SECURITY CONTROLS                                          │          │
│  │ • Security Groups (Stateful)                               │          │
│  │ • Network ACLs (Stateless)                                 │          │
│  │ • VPC Flow Logs → CloudWatch/S3                            │          │
│  │ • Internet Gateway (Public subnets only)                   │          │
│  │ • Route Tables (Subnet-specific)                           │          │
│  └────────────────────────────────────────────────────────────┘          │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────────┘

EXTERNAL SERVICES:
┌────────────────┐         ┌────────────────┐         ┌────────────────┐
│   CloudWatch   │         │   CloudTrail   │         │ Secrets Manager│
└────────────────┘         └────────────────┘         └────────────────┘
```

### Trust Boundaries
- **TB1:** Public ↔ Private subnets
- **TB2:** Private ↔ Data subnets
- **TB3:** VPC ↔ Internet (via IGW)
- **TB4:** VPC ↔ AWS Services (via VPC Endpoints)

---

## 3. THREAT ENUMERATION (STRIDE ANALYSIS)

### Component 1: Application Load Balancer (ALB)

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-S1 | Attacker spoofs legitimate domain using DNS hijacking | LOW | HIGH | MEDIUM |
| VPC-ALB-S2 | TLS certificate is compromised or fake cert presented | LOW | CRITICAL | MEDIUM |
| VPC-ALB-S3 | Attacker intercepts traffic via ARP spoofing (within VPC) | VERY LOW | HIGH | LOW |

**Mitigations:**
- ✅ TLS certificate from trusted CA (AWS Certificate Manager)
- ✅ Certificate pinning (application-level, if applicable)
- ✅ DNS validation (Route 53 DNSSEC where available)
- ✅ VPC network isolation prevents internal spoofing

**Residual Risk:** LOW

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-T1 | Man-in-the-middle modifies request/response | LOW | HIGH | MEDIUM |
| VPC-ALB-T2 | Attacker modifies ALB configuration via AWS API | LOW | CRITICAL | MEDIUM |
| VPC-ALB-T3 | ALB listener rules modified to redirect traffic | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ TLS encryption end-to-end (Internet → ALB)
- ✅ IAM policies restrict ALB modifications (least privilege)
- ✅ CloudTrail logging of all API calls
- ✅ Resource-based policies on ALB
- ⚠️ RECOMMENDED: Enable AWS Config rules to detect config changes
- ⚠️ RECOMMENDED: Use Service Control Policies (SCPs) to prevent deletion

**Residual Risk:** LOW

---

#### REPUDIATION
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-R1 | User denies making malicious request | MEDIUM | MEDIUM | MEDIUM |
| VPC-ALB-R2 | Cannot prove who modified ALB configuration | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ ALB access logs enabled (sent to S3)
- ✅ Logs contain: timestamp, client IP, request, response, user-agent
- ✅ CloudTrail logs all IAM principal actions
- ✅ Log immutability via S3 Object Lock (recommended)
- ✅ Centralized logging reduces tampering risk

**Residual Risk:** LOW

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-I1 | ALB exposes internal error messages with sensitive data | MEDIUM | MEDIUM | MEDIUM |
| VPC-ALB-I2 | ALB access logs contain PII/secrets in URLs | MEDIUM | HIGH | MEDIUM |
| VPC-ALB-I3 | TLS configuration allows weak ciphers | LOW | HIGH | MEDIUM |
| VPC-ALB-I4 | Attacker accesses S3 bucket with ALB logs | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ Custom error pages (do not expose stack traces)
- ⚠️ RECOMMENDED: Scrub sensitive data from logs before storage
- ✅ TLS Security Policy: ELBSecurityPolicy-TLS-1-2-2017-01 or newer
- ✅ S3 bucket encryption (KMS)
- ✅ S3 bucket policy: private only, no public access
- ✅ S3 Block Public Access enabled

**Residual Risk:** MEDIUM (due to potential PII in logs)

**Recommendation:** Implement log scrubbing or use AWS WAF to strip sensitive headers

---

#### DENIAL OF SERVICE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-D1 | DDoS attack overwhelms ALB capacity | HIGH | HIGH | HIGH |
| VPC-ALB-D2 | Slowloris or slow POST attack exhausts connections | MEDIUM | MEDIUM | MEDIUM |
| VPC-ALB-D3 | Attacker deletes ALB via compromised AWS credentials | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ AWS Shield Standard (automatic DDoS protection)
- ⚠️ RECOMMENDED: AWS Shield Advanced for Layer 7 protection
- ⚠️ RECOMMENDED: AWS WAF with rate limiting rules
- ✅ ALB auto-scales based on traffic
- ✅ IAM policies prevent unauthorized deletion
- ✅ CloudWatch alarms on 5XX errors and high request count

**Residual Risk:** MEDIUM (without WAF rate limiting)

**Recommendation:** Enable AWS WAF with rate-based rules (10,000 req/5min per IP)

---

#### ELEVATION OF PRIVILEGE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-ALB-E1 | Attacker gains AWS console access to modify ALB | LOW | CRITICAL | MEDIUM |
| VPC-ALB-E2 | Misconfigured IAM role allows privilege escalation | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ IAM least privilege (no * permissions)
- ✅ MFA required for all privileged actions
- ✅ CloudTrail alerts on IAM policy changes
- ✅ No long-lived access keys (use IAM roles)
- ✅ Regular IAM Access Analyzer scans

**Residual Risk:** LOW

---

### Component 2: EC2/ECS Application Servers (Private Subnet)

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-S1 | Attacker assumes IAM role via SSRF to IMDS | MEDIUM | CRITICAL | HIGH |
| VPC-APP-S2 | Stolen SSH keys used to impersonate admin | LOW | HIGH | MEDIUM |
| VPC-APP-S3 | Container running with forged image signature | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ IMDSv2 enforced (requires signed token, prevents SSRF)
- ✅ No SSH access (use AWS Systems Manager Session Manager)
- ✅ IAM instance profile with minimal permissions
- ⚠️ RECOMMENDED: Container image signing with AWS Signer
- ⚠️ RECOMMENDED: Use ECR image scanning

**Residual Risk:** MEDIUM (if container scanning not enabled)

**Recommendation:** Enable ECR scan-on-push and block images with CRITICAL vulnerabilities

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-T1 | Attacker modifies application code on running instance | MEDIUM | CRITICAL | HIGH |
| VPC-APP-T2 | Malicious package injected via compromised dependency | MEDIUM | CRITICAL | HIGH |
| VPC-APP-T3 | Environment variables modified to exfiltrate secrets | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ Immutable infrastructure (containers replaced, not patched)
- ✅ KICS scanning in CI/CD pipeline
- ⚠️ RECOMMENDED: Software Composition Analysis (SCA) for dependencies
- ✅ Secrets retrieved from Secrets Manager (not env vars)
- ✅ CloudWatch logs capture all container activity
- ⚠️ RECOMMENDED: File integrity monitoring (FIM) with tools like Wazuh

**Residual Risk:** MEDIUM (without SCA/FIM)

**Recommendation:** Implement Snyk or Dependabot for dependency scanning

---

#### REPUDIATION
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-R1 | Application activity not logged (cannot prove actions) | LOW | HIGH | MEDIUM |
| VPC-APP-R2 | Logs are deleted or tampered with | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ Application logs sent to CloudWatch Logs
- ✅ CloudWatch Logs encrypted with KMS
- ✅ Log retention: 30 days (configurable)
- ✅ VPC Flow Logs capture all network activity
- ✅ CloudTrail captures all IAM/API actions
- ⚠️ RECOMMENDED: Send logs to immutable storage (S3 with Object Lock)

**Residual Risk:** LOW

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-I1 | SSRF attack accesses IMDS and retrieves IAM credentials | MEDIUM | CRITICAL | HIGH |
| VPC-APP-I2 | Secrets leaked in application logs or error messages | MEDIUM | HIGH | HIGH |
| VPC-APP-I3 | Unencrypted data in memory dumped via debugging tools | LOW | HIGH | MEDIUM |
| VPC-APP-I4 | EBS snapshots contain sensitive data and are public | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ IMDSv2 required (prevents simple SSRF)
- ✅ Secrets Manager integration (no secrets in code)
- ⚠️ RECOMMENDED: Input validation to prevent SSRF attacks
- ⚠️ RECOMMENDED: Log scrubbing (remove passwords, tokens before logging)
- ✅ EBS encryption enabled by default
- ✅ EBS snapshots encrypted with KMS
- ✅ Snapshot sharing disabled (private only)

**Residual Risk:** MEDIUM (if log scrubbing not implemented)

**Recommendation:** Implement regex-based log scrubbing for common secret patterns

---

#### DENIAL OF SERVICE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-D1 | Resource exhaustion attack (CPU/memory bomb) | MEDIUM | HIGH | MEDIUM |
| VPC-APP-D2 | Instance terminated via compromised AWS credentials | LOW | HIGH | MEDIUM |
| VPC-APP-D3 | Dependency availability failure (npm/Docker Hub outage) | MEDIUM | MEDIUM | MEDIUM |

**Mitigations:**
- ✅ Auto-scaling based on CPU/memory metrics
- ✅ CloudWatch alarms trigger auto-scaling
- ✅ Health checks remove unhealthy instances
- ✅ IAM policies prevent unauthorized termination
- ⚠️ RECOMMENDED: Use VPC Endpoints for AWS services (no internet dependency)
- ⚠️ RECOMMENDED: Cache Docker images in ECR
- ⚠️ RECOMMENDED: Use CodeArtifact for package dependencies

**Residual Risk:** MEDIUM (external dependency risk)

**Recommendation:** Mirror critical dependencies in private registries

---

#### ELEVATION OF PRIVILEGE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-APP-E1 | Container escape leads to host compromise | LOW | CRITICAL | MEDIUM |
| VPC-APP-E2 | IAM role permissions allow privilege escalation | LOW | CRITICAL | MEDIUM |
| VPC-APP-E3 | Kernel exploit gains root access | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ Containers run as non-root user
- ✅ Security Groups prevent lateral movement
- ✅ IAM policies use least privilege (no admin access)
- ✅ Regular patching via immutable infrastructure
- ⚠️ RECOMMENDED: Use AWS Fargate (no host access)
- ⚠️ RECOMMENDED: Enable GuardDuty for anomaly detection
- ⚠️ RECOMMENDED: Runtime security (Falco, Aqua Security)

**Residual Risk:** MEDIUM (without runtime protection)

**Recommendation:** Enable GuardDuty and implement runtime security monitoring

---

### Component 3: RDS Database (Data Subnet)

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-S1 | Attacker uses stolen database credentials | MEDIUM | CRITICAL | HIGH |
| VPC-DB-S2 | Application connects to rogue database (DNS poisoning) | VERY LOW | CRITICAL | LOW |

**Mitigations:**
- ✅ Database credentials stored in Secrets Manager
- ✅ Automatic credential rotation (90 days)
- ✅ Private DNS only (no public resolution)
- ✅ TLS-only connections enforced
- ✅ Certificate validation in application

**Residual Risk:** MEDIUM (credential theft still possible)

**Recommendation:** Implement IAM database authentication where supported

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-T1 | SQL injection modifies or deletes data | MEDIUM | CRITICAL | HIGH |
| VPC-DB-T2 | Attacker modifies RDS configuration via AWS API | LOW | CRITICAL | MEDIUM |
| VPC-DB-T3 | Backup files tampered with | LOW | HIGH | MEDIUM |

**Mitigations:**
- ⚠️ APPLICATION RESPONSIBILITY: Use prepared statements (prevent SQL injection)
- ⚠️ RECOMMENDED: Web Application Firewall (WAF) to detect SQL injection attempts
- ✅ IAM policies restrict RDS modifications
- ✅ CloudTrail logs all RDS API calls
- ✅ Automated backups with encryption
- ✅ Backup retention: 7 days

**Residual Risk:** MEDIUM (application-level SQL injection risk)

**Recommendation:** Implement SAST (Static Application Security Testing) in CI/CD to detect SQL injection vulnerabilities

---

#### REPUDIATION
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-R1 | Database queries not logged (cannot prove malicious activity) | MEDIUM | HIGH | MEDIUM |
| VPC-DB-R2 | User denies unauthorized data access | MEDIUM | HIGH | MEDIUM |

**Mitigations:**
- ✅ RDS audit logging enabled (slow query log, general log)
- ✅ Logs sent to CloudWatch Logs
- ✅ Log retention: 30 days minimum
- ⚠️ RECOMMENDED: Application-level audit logging (who accessed what, when)

**Residual Risk:** MEDIUM (without application-level logging)

**Recommendation:** Implement application audit logs for sensitive data access

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-I1 | Database exposed to internet (misconfiguration) | VERY LOW | CRITICAL | LOW |
| VPC-DB-I2 | Snapshot shared publicly | LOW | CRITICAL | MEDIUM |
| VPC-DB-I3 | Data exfiltration via SQL injection | MEDIUM | CRITICAL | HIGH |
| VPC-DB-I4 | Unencrypted data at rest | VERY LOW | CRITICAL | LOW |

**Mitigations:**
- ✅ RDS in private subnet only (no internet access)
- ✅ Security Group allows connections only from app tier
- ✅ Encryption at rest enabled (KMS)
- ✅ Encryption in transit enforced (TLS)
- ✅ Snapshot encryption enabled
- ✅ Snapshot sharing disabled (private only)
- ⚠️ APPLICATION: Input validation to prevent SQL injection

**Residual Risk:** MEDIUM (SQL injection at app level)

**Recommendation:** Implement database activity monitoring (DAM) tool

---

#### DENIAL OF SERVICE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-D1 | Connection exhaustion attack (too many connections) | MEDIUM | HIGH | MEDIUM |
| VPC-DB-D2 | Storage exhaustion (disk full) | MEDIUM | HIGH | MEDIUM |
| VPC-DB-D3 | RDS instance deleted via compromised credentials | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ RDS connection limit configured
- ✅ CloudWatch alarm on high connection count
- ✅ Storage auto-scaling enabled
- ✅ CloudWatch alarm on low disk space
- ✅ Multi-AZ deployment (automatic failover)
- ✅ IAM policies prevent unauthorized deletion
- ✅ Automated backups (point-in-time recovery)

**Residual Risk:** LOW

---

#### ELEVATION OF PRIVILEGE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| VPC-DB-E1 | Attacker gains admin access to database via compromised app | MEDIUM | CRITICAL | HIGH |
| VPC-DB-E2 | SQL injection allows privilege escalation (UNION-based) | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ Application uses least-privilege database user (no admin rights)
- ✅ Separate database users for different application functions
- ⚠️ APPLICATION: Input validation prevents SQL injection
- ⚠️ RECOMMENDED: Database firewall or monitoring tool

**Residual Risk:** MEDIUM

**Recommendation:** Use database-level RBAC and implement query whitelisting

---

## 4. RISK ASSESSMENT

### Critical Findings (Immediate Action Required)

| ID | Threat | Current Risk | Mitigation Priority |
|----|--------|--------------|---------------------|
| VPC-APP-I1 | SSRF to IMDS retrieves credentials | HIGH | Implement SSRF protection in application |
| VPC-DB-T1 | SQL injection leads to data breach | HIGH | SAST in CI/CD + WAF rules |
| VPC-DB-I3 | Data exfiltration via SQL injection | HIGH | Input validation + DAM |
| VPC-APP-S1 | SSRF via IMDSv1 (if not fully enforced) | HIGH | Verify IMDSv2 enforcement |

### High Findings (Mitigate within 30 days)

| ID | Threat | Current Risk | Recommended Mitigation |
|----|--------|--------------|------------------------|
| VPC-ALB-D1 | DDoS attack without WAF | HIGH | Enable AWS WAF with rate limiting |
| VPC-APP-T2 | Malicious dependency injection | HIGH | Implement SCA (Snyk/Dependabot) |
| VPC-DB-S1 | Stolen database credentials | MEDIUM | Enable IAM database authentication |

### Medium Findings (Mitigate within 90 days)

| ID | Threat | Current Risk | Recommended Mitigation |
|----|--------|--------------|------------------------|
| VPC-APP-E3 | Kernel exploit / container escape | MEDIUM | Enable GuardDuty + runtime security |
| VPC-APP-D3 | External dependency failure | MEDIUM | Mirror dependencies in ECR/CodeArtifact |
| VPC-ALB-I2 | PII in ALB access logs | MEDIUM | Implement log scrubbing |

---

## 5. MITIGATIONS

### Existing Controls (Implemented ✅)

#### Network Security
- ✅ Multi-tier VPC architecture (public/private/data)
- ✅ Security Groups (stateful firewall)
- ✅ Network ACLs (stateless firewall)
- ✅ Private subnets for application and database tiers
- ✅ NAT Gateways for controlled outbound access
- ✅ VPC Flow Logs enabled
- ✅ VPC Endpoints for AWS services

#### Encryption
- ✅ TLS 1.2+ for all external connections
- ✅ RDS encryption at rest (KMS)
- ✅ RDS encryption in transit (TLS required)
- ✅ EBS encryption enabled
- ✅ S3 encryption (KMS)
- ✅ CloudWatch Logs encryption (KMS)
- ✅ Secrets Manager encryption (KMS)

#### Identity & Access
- ✅ IAM roles with least privilege
- ✅ No long-lived access keys (CI/CD uses OIDC)
- ✅ IMDSv2 enforced on EC2 instances
- ✅ Systems Manager Session Manager (no SSH)
- ✅ Secrets rotation (90 days)

#### Logging & Monitoring
- ✅ CloudTrail (all API calls)
- ✅ VPC Flow Logs (all network traffic)
- ✅ ALB access logs
- ✅ RDS audit logs
- ✅ CloudWatch Logs (application logs)
- ✅ Log retention policies

#### Resilience
- ✅ Multi-AZ deployment
- ✅ Auto-scaling groups
- ✅ Automated backups (RDS)
- ✅ Health checks and auto-recovery

---

### Recommended Additional Controls (⚠️)

#### Priority 1 (Immediate - within 7 days)
1. **Application Input Validation**
   - Implement strict input validation to prevent SSRF
   - Use allowlists for URLs and IP addresses
   - Validate and sanitize all user inputs

2. **SAST in CI/CD**
   - Add SAST tool (e.g., Semgrep, SonarQube) to pipeline
   - Fail builds on CRITICAL/HIGH findings
   - Detect SQL injection, XSS, SSRF vulnerabilities

#### Priority 2 (within 30 days)
3. **AWS WAF on ALB**
   - Enable AWS Managed Rules (Core Rule Set, SQL Database)
   - Implement rate limiting (10,000 requests per 5 minutes per IP)
   - Block known bad IPs (AWS Managed IP Reputation List)

4. **Container Security**
   - Enable ECR image scanning (scan on push)
   - Implement image signing with AWS Signer
   - Block deployment of images with CRITICAL vulnerabilities

5. **Software Composition Analysis (SCA)**
   - Integrate Snyk or Dependabot in CI/CD
   - Scan for known vulnerabilities in dependencies
   - Automated PR creation for security updates

#### Priority 3 (within 90 days)
6. **Runtime Security**
   - Enable AWS GuardDuty for threat detection
   - Implement runtime application self-protection (RASP)
   - Consider Falco for container runtime security

7. **Database Activity Monitoring**
   - Implement DAM tool (e.g., Imperva, GreenSQL)
   - Alert on suspicious query patterns
   - Baseline normal database activity

8. **Dependency Mirroring**
   - Set up AWS CodeArtifact for npm/pip packages
   - Use ECR for Docker base images
   - Reduce external dependency risk

9. **Log Scrubbing**
   - Implement regex-based secret detection in logs
   - Redact PII before storing in CloudWatch/S3
   - Use tools like git-secrets for pre-commit scanning

---

### Residual Risks (Accepted)

| Risk | Justification | Owner |
|------|---------------|-------|
| Low likelihood physical attacks | Cloud provider responsibility | AWS |
| Zero-day vulnerabilities | Accepted, mitigated by patching cadence | Security Team |
| Advanced persistent threats (nation-state) | Out of scope for current threat model | CISO |

---

## 6. VALIDATION

### How Will Mitigations Be Tested?

#### Security Testing
- ✅ **Penetration Testing:** Annual third-party pentest
- ✅ **Vulnerability Scanning:** Weekly automated scans (AWS Inspector)
- ✅ **SAST:** Every commit in CI/CD pipeline
- ⚠️ **DAST:** Recommended quarterly (e.g., OWASP ZAP)
- ⚠️ **Red Team Exercise:** Recommended annually

#### Compliance Validation
- ✅ **AWS Config Rules:** Automated compliance checks
- ✅ **Security Hub:** Aggregated security findings
- ⚠️ **Third-party Audit:** Recommended for SOC 2 compliance

#### Monitoring Effectiveness
- ✅ **CloudWatch Alarms:** Test alarm triggers monthly
- ✅ **Incident Response Drills:** Quarterly tabletop exercises
- ✅ **Log Review:** Weekly manual review of high-severity events

---

### Review Schedule

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Threat model review | Quarterly | Security Team |
| Architecture changes trigger review | Ad-hoc | DevOps Team |
| Post-incident review | After incidents | Incident Response Team |
| Annual comprehensive review | Annually | CISO |

---

## 7. ATTACK SCENARIOS

### Scenario 1: Data Breach via SQL Injection

**Attack Chain:**
```
1. Attacker discovers SQLi vulnerability in application
2. Exploits SQLi to dump database credentials
3. Establishes persistent database connection
4. Exfiltrates customer PII over multiple days
5. Sells data on dark web
```

**Likelihood:** MEDIUM
**Impact:** CRITICAL
**Current Risk:** HIGH

**Mitigations:**
- ✅ WAF with SQL injection rules
- ✅ Database activity monitoring
- ✅ SAST in CI/CD
- ⚠️ Input validation (application responsibility)

**Residual Risk:** MEDIUM (dependent on application code quality)

---

### Scenario 2: Infrastructure Takeover via SSRF

**Attack Chain:**
```
1. Attacker finds SSRF vulnerability in application
2. Uses SSRF to access IMDSv2 (requires token, more difficult)
3. Retrieves IAM role credentials
4. Uses credentials to escalate privileges in AWS account
5. Creates backdoor IAM user
6. Deploys malicious infrastructure
```

**Likelihood:** LOW (IMDSv2 makes this harder)
**Impact:** CRITICAL
**Current Risk:** MEDIUM

**Mitigations:**
- ✅ IMDSv2 enforced
- ✅ IAM least privilege
- ✅ GuardDuty anomaly detection
- ⚠️ Application SSRF protection

**Residual Risk:** LOW (with IMDSv2)

---

### Scenario 3: Supply Chain Attack

**Attack Chain:**
```
1. Attacker compromises npm package used by application
2. Malicious code injected into build process
3. Backdoor deployed to production
4. Attacker gains persistent access to customer data
```

**Likelihood:** MEDIUM
**Impact:** CRITICAL
**Current Risk:** HIGH

**Mitigations:**
- ✅ KICS scanning (infrastructure)
- ⚠️ SCA for application dependencies (recommended)
- ⚠️ Dependency pinning (package-lock.json)
- ⚠️ Private package mirror (CodeArtifact)

**Residual Risk:** MEDIUM

---

## SUMMARY

### Security Posture: GOOD ✅

The VPC infrastructure demonstrates **strong security fundamentals**:
- Multi-tier architecture with defense in depth
- Encryption at rest and in transit
- Comprehensive logging and monitoring
- IAM least privilege
- No public database exposure

### Key Gaps Identified:
1. No WAF on ALB (DDoS/injection vulnerability)
2. No application-level input validation (SSRF/SQLi risk)
3. No container scanning (malicious image risk)
4. No SCA for dependencies (supply chain risk)

### Recommended Next Steps:
1. **Week 1:** Implement SAST in CI/CD pipeline
2. **Week 2:** Enable AWS WAF with managed rules
3. **Week 3:** Add ECR image scanning
4. **Week 4:** Integrate SCA tool (Snyk/Dependabot)

---

**Document Classification:** CONFIDENTIAL
**Version:** 1.0
**Last Updated:** February 14, 2026
**Next Review:** May 14, 2026
**Owner:** DevSecOps Team
**Approver:** CISO
