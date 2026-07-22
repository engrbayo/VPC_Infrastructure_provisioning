# CI/CD Pipeline Threat Model

## 1. SYSTEM OVERVIEW

### What is Being Built?
A GitHub Actions-based CI/CD pipeline that:
- Performs security scanning (KICS) on infrastructure code
- Deploys AWS infrastructure using Terraform
- Uses OIDC for authentication (no long-lived credentials)
- Supports multiple environments (dev, staging, prod)

### Pipeline Components
1. **Source Control:** GitHub repository
2. **CI/CD Platform:** GitHub Actions
3. **Security Scanning:** KICS (Infrastructure as Code scanner)
4. **Deployment Tool:** Terraform
5. **State Management:** S3 backend with DynamoDB locking
6. **Secrets:** GitHub Secrets + AWS Secrets Manager

---

## 2. ARCHITECTURE DIAGRAM

```
┌──────────────────────────────────────────────────────────────────┐
│                     DEVELOPER WORKSTATION                        │
│  ┌────────┐        ┌────────┐        ┌────────┐                 │
│  │  IDE   │───────▶│  Git   │───────▶│ GitHub │                 │
│  └────────┘        └────────┘        └───┬────┘                 │
└────────────────────────────────────────────┼────────────────────┘
                                             │
                     ════════════════════════╪════  TB1: Developer → GitHub
                                             │
┌────────────────────────────────────────────▼────────────────────┐
│                      GITHUB PLATFORM                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  REPOSITORY                                              │   │
│  │  ├─ main.tf                                              │   │
│  │  ├─ .github/workflows/terraform-deploy.yml              │   │
│  │  ├─ Branch protection rules                             │   │
│  │  └─ CODEOWNERS file                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            │ Webhook trigger                    │
│                            ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  GITHUB ACTIONS WORKFLOW                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │   │
│  │  │ Checkout │─▶│   KICS   │─▶│ TF Plan  │─▶│ TF Apply │ │   │
│  │  │   Code   │  │   Scan   │  │          │  │          │ │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │   │
│  └──────────────────────────────────────────┬───────────────┘   │
└─────────────────────────────────────────────┼───────────────────┘
                                              │
                     ═════════════════════════╪════  TB2: GitHub → AWS
                                              │
                                              │ OIDC Authentication
                                              ▼
┌────────────────────────────────────────────────────────────────┐
│                         AWS ACCOUNT                            │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐       │
│  │   IAM OIDC   │──▶│ Terraform    │──▶│     VPC      │       │
│  │   Provider   │   │ State (S3)   │   │ Infrastructure│       │
│  └──────────────┘   └──────────────┘   └──────────────┘       │
└────────────────────────────────────────────────────────────────┘
```

### Trust Boundaries
- **TB1:** Developer → GitHub (authentication, code integrity)
- **TB2:** GitHub → AWS (authorization, deployment)
- **TB3:** Terraform → AWS Resources (privilege scope)

---

## 3. THREAT ENUMERATION (STRIDE ANALYSIS)

### Component 1: GitHub Repository

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-REPO-S1 | Attacker compromises developer account | MEDIUM | CRITICAL | HIGH |
| CICD-REPO-S2 | Forged git commits with fake identity | LOW | MEDIUM | LOW |

**Mitigations:**
- ✅ Require MFA for all developers
- ✅ Branch protection rules prevent direct pushes to main
- ✅ Require pull request reviews (2 reviewers minimum)
- ⚠️ RECOMMENDED: Require signed commits (GPG/SSH)
- ✅ CODEOWNERS file enforces review by specific teams

**Residual Risk:** MEDIUM

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-REPO-T1 | Malicious code merged via compromised account | MEDIUM | CRITICAL | HIGH |
| CICD-REPO-T2 | Workflow file modified to bypass security checks | LOW | CRITICAL | MEDIUM |
| CICD-REPO-T3 | Secrets injected into repository | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ Required PR reviews (cannot approve own PR)
- ✅ CODEOWNERS for .github/workflows (requires security team approval)
- ✅ Status checks must pass before merge (KICS scan)
- ✅ No direct commits to main/production branches
- ⚠️ RECOMMENDED: Implement code review checklist
- ⚠️ RECOMMENDED: Use GitHub secret scanning

**Residual Risk:** MEDIUM

**Recommendation:** Enable GitHub Advanced Security for secret scanning and code scanning

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-REPO-I1 | Secrets accidentally committed to repository | MEDIUM | CRITICAL | HIGH |
| CICD-REPO-I2 | Repository made public by mistake | LOW | CRITICAL | MEDIUM |
| CICD-REPO-I3 | Terraform state file contains sensitive data | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ .gitignore file prevents committing sensitive files
- ⚠️ RECOMMENDED: Pre-commit hooks with git-secrets
- ✅ Repository visibility: Private
- ✅ Terraform state stored remotely in S3 (encrypted)
- ✅ State file access restricted via IAM policies
- ⚠️ RECOMMENDED: Use GitHub secret scanning alerts

**Residual Risk:** MEDIUM

**Recommendation:** Implement pre-commit hooks with Yelp's detect-secrets or AWS git-secrets

---

### Component 2: GitHub Actions Workflow

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-WORKFLOW-S1 | Workflow assumes wrong AWS account via OIDC | LOW | CRITICAL | MEDIUM |
| CICD-WORKFLOW-S2 | Forged workflow run from external fork | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ OIDC subject claim restricts assumed role to specific repo
- ✅ Workflow runs disabled for forks
- ✅ IAM trust policy validates GitHub token claims
- ✅ Separate IAM roles per environment (dev/staging/prod)

**Residual Risk:** LOW

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-WORKFLOW-T1 | Malicious code injected via compromised action | MEDIUM | CRITICAL | HIGH |
| CICD-WORKFLOW-T2 | Attacker modifies workflow to skip KICS scan | LOW | HIGH | MEDIUM |
| CICD-WORKFLOW-T3 | Environment variables modified to inject secrets | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ Pin actions to specific commit SHA (not @latest)
- ✅ CODEOWNERS requires security team approval for workflow changes
- ✅ KICS scan runs as separate required check
- ⚠️ RECOMMENDED: Use GitHub Actions third-party action auditing
- ⚠️ RECOMMENDED: Implement workflow linting (actionlint)

**Residual Risk:** MEDIUM

**Recommendation:** Use only verified actions from trusted publishers

---

#### DENIAL OF SERVICE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-WORKFLOW-D1 | Resource exhaustion via malicious PR | LOW | MEDIUM | LOW |
| CICD-WORKFLOW-D2 | Workflow concurrency limits exceeded | LOW | MEDIUM | LOW |

**Mitigations:**
- ✅ Workflow requires approval for first-time contributors
- ✅ Concurrency limits prevent multiple simultaneous runs
- ✅ Timeout limits on workflow jobs (30 minutes max)

**Residual Risk:** LOW

---

### Component 3: Terraform State

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-STATE-T1 | State file modified directly in S3 | LOW | CRITICAL | MEDIUM |
| CICD-STATE-T2 | State lock bypassed, causing race condition | LOW | HIGH | MEDIUM |

**Mitigations:**
- ✅ S3 bucket versioning enabled
- ✅ State locking via DynamoDB
- ✅ S3 bucket policy restricts access to CI/CD role only
- ✅ MFA delete enabled on S3 bucket
- ✅ CloudTrail logs all S3 access

**Residual Risk:** LOW

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| CICD-STATE-I1 | Terraform state contains secrets (DB passwords) | MEDIUM | CRITICAL | HIGH |
| CICD-STATE-I2 | S3 bucket accidentally made public | LOW | CRITICAL | MEDIUM |

**Mitigations:**
- ✅ S3 bucket encryption with KMS
- ✅ S3 Block Public Access enabled
- ✅ State file access restricted via IAM
- ⚠️ BEST PRACTICE: Never store secrets in Terraform state (use Secrets Manager)
- ⚠️ RECOMMENDED: Use terraform remote state data source with output filtering

**Residual Risk:** MEDIUM (if secrets exist in state)

**Recommendation:** Audit Terraform state for sensitive data, migrate secrets to Secrets Manager

---

## 4. ATTACK SCENARIOS

### Scenario 1: Supply Chain Attack via Compromised GitHub Action

```
┌─────────────────────────────────────────────────────────────────┐
│                    ATTACK TREE                                  │
└─────────────────────────────────────────────────────────────────┘

                   ┌──────────────────────────┐
                   │  Compromise Production   │
                   │      Infrastructure      │
                   └────────────┬─────────────┘
                                │
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐      ┌────────────────┐     ┌───────────────┐
│ Compromise    │      │ Modify         │     │ Steal AWS     │
│ GitHub Action │      │ Workflow File  │     │ Credentials   │
└───────┬───────┘      └───────┬────────┘     └───────┬───────┘
        │                      │                      │
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌────────────────┐     ┌───────────────┐
│ Inject        │      │ Bypass KICS    │     │ Extract OIDC  │
│ Malicious Code│      │ Security Scan  │     │ Token         │
└───────┬───────┘      └───────┬────────┘     └───────┬───────┘
        │                      │                      │
        └──────────────────────┴──────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │ Deploy Backdoor to    │
                    │ Production VPC        │
                    └───────────────────────┘

Risk: HIGH
Likelihood: MEDIUM
Impact: CRITICAL

Mitigations:
✅ Pin actions to commit SHA
✅ CODEOWNERS for workflow changes
⚠️ RECOMMENDED: Third-party action auditing
⚠️ RECOMMENDED: GitHub Advanced Security
```

---

### Scenario 2: Developer Account Compromise

```
1. Attacker phishes developer credentials
2. Bypasses MFA using social engineering
3. Creates malicious branch with backdoor code
4. Opens pull request
5. If no code review or reviewer is compromised:
   → Merges to main
6. Workflow deploys backdoor to production
7. Attacker gains persistent access to AWS

Likelihood: MEDIUM
Impact: CRITICAL
Risk: HIGH

Mitigations:
✅ MFA required
✅ 2-person PR review
✅ KICS scan blocks known issues
✅ CODEOWNERS enforces security team review
⚠️ RECOMMENDED: Security awareness training
⚠️ RECOMMENDED: Require hardware security keys (YubiKey)
```

---

### Scenario 3: Secrets Leakage in Workflow Logs

```
1. Developer accidentally logs sensitive environment variable
2. Workflow run completes successfully
3. Attacker with read access to repository views logs
4. Extracts AWS credentials or database passwords
5. Uses credentials to access production resources

Likelihood: MEDIUM
Impact: HIGH
Risk: MEDIUM

Mitigations:
✅ GitHub automatically masks secrets in logs
✅ Secrets stored in GitHub Secrets (encrypted)
✅ Short-lived OIDC tokens (no long-lived credentials)
⚠️ RECOMMENDED: Log review process
⚠️ RECOMMENDED: Detect sensitive data in logs (regex scanning)
```

---

## 5. RISK ASSESSMENT

### Critical Findings

| ID | Threat | Current Risk | Mitigation |
|----|--------|--------------|------------|
| CICD-REPO-I1 | Secrets committed to repository | HIGH | Pre-commit hooks + secret scanning |
| CICD-WORKFLOW-T1 | Compromised GitHub Action | HIGH | Pin to SHA + action auditing |

### High Findings

| ID | Threat | Current Risk | Mitigation |
|----|--------|--------------|------------|
| CICD-REPO-T1 | Malicious code merged | MEDIUM | Code review + security training |
| CICD-STATE-I1 | Secrets in Terraform state | MEDIUM | Migrate secrets to Secrets Manager |

---

## 6. MITIGATIONS

### Existing Controls ✅

1. **Authentication & Authorization**
   - MFA required for all developers
   - OIDC authentication (no long-lived credentials)
   - IAM least privilege roles

2. **Code Protection**
   - Branch protection rules
   - Required PR reviews (2 approvers)
   - CODEOWNERS file
   - KICS security scanning

3. **Infrastructure Protection**
   - Terraform state encryption (KMS)
   - State locking (DynamoDB)
   - S3 versioning + Block Public Access

4. **Monitoring**
   - CloudTrail logs all AWS API calls
   - GitHub audit logs
   - Workflow run history

### Recommended Controls ⚠️

**Priority 1 (Immediate)**
1. Enable GitHub secret scanning
2. Implement pre-commit hooks (git-secrets)
3. Pin all GitHub Actions to commit SHA

**Priority 2 (30 days)**
4. Migrate secrets from Terraform state to Secrets Manager
5. Implement code review checklist
6. Enable GitHub Advanced Security

**Priority 3 (90 days)**
7. Require signed commits (GPG)
8. Implement hardware security keys (YubiKey)
9. Third-party action security auditing

---

## 7. VALIDATION

### Testing
- ✅ Weekly: Automated KICS scans
- ⚠️ Recommended: Quarterly pipeline security review
- ⚠️ Recommended: Annual third-party security assessment

### Monitoring
- ✅ GitHub audit log review (weekly)
- ✅ CloudTrail monitoring for suspicious activity
- ⚠️ Recommended: Alerts on workflow file changes

### Review Schedule
- **Quarterly:** Threat model review
- **Ad-hoc:** After security incidents
- **Annually:** Comprehensive assessment

---

**Document Classification:** CONFIDENTIAL
**Version:** 1.0
**Last Updated:** February 14, 2026
**Next Review:** May 14, 2026
**Owner:** DevSecOps Team
