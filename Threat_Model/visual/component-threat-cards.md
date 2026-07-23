# Component Threat Cards

## Component Card: Application Load Balancer (ALB)

```
╔══════════════════════════════════════════════════════════════════╗
║                  ⚖️  APPLICATION LOAD BALANCER                   ║
║                        THREAT CARD                               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  OVERALL RISK LEVEL: 🔴 CRITICAL (Score: 85/100)                ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ COMPONENT DETAILS                                          │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ Name:            production-alb                            │ ║
║  │ Type:            Application Load Balancer                 │ ║
║  │ Exposure:        🌐 Public Internet                        │ ║
║  │ Data Handled:    Customer requests, Session tokens         │ ║
║  │ Availability:    99.99% SLA                                │ ║
║  │ Listeners:       HTTP (80), HTTPS (443)                    │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ STRIDE THREAT BREAKDOWN                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  S - SPOOFING              🔴 CRITICAL                     │ ║
║  │      ██████████████████░░  90/100                          │ ║
║  │      • DNS Hijacking                                       │ ║
║  │      • Certificate Theft                                   │ ║
║  │      • Domain Impersonation                                │ ║
║  │                                                            │ ║
║  │  T - TAMPERING             🟠 HIGH                         │ ║
║  │      ███████████████░░░░░  75/100                          │ ║
║  │      • Man-in-the-Middle                                   │ ║
║  │      • SSL Stripping                                       │ ║
║  │      • Request Manipulation                                │ ║
║  │                                                            │ ║
║  │  R - REPUDIATION           🟡 MEDIUM                       │ ║
║  │      ████████░░░░░░░░░░░░  45/100                          │ ║
║  │      • Missing Access Logs                                 │ ║
║  │      • Log Retention Issues                                │ ║
║  │                                                            │ ║
║  │  I - INFO DISCLOSURE       🟠 HIGH                         │ ║
║  │      ██████████████░░░░░░  70/100                          │ ║
║  │      • Certificate Exposure                                │ ║
║  │      • Header Information Leakage                          │ ║
║  │      • Error Message Details                               │ ║
║  │                                                            │ ║
║  │  D - DENIAL OF SERVICE     🔴 CRITICAL                     │ ║
║  │      █████████████████████  95/100                         │ ║
║  │      • DDoS Layer 7 Attacks                                │ ║
║  │      • Resource Exhaustion                                 │ ║
║  │      • Slowloris Attack                                    │ ║
║  │                                                            │ ║
║  │  E - ELEVATION             🟡 MEDIUM                       │ ║
║  │      ██████░░░░░░░░░░░░░░  35/100                          │ ║
║  │      • ALB Configuration Change                            │ ║
║  │      • Routing Rule Manipulation                           │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ EXISTING CONTROLS                                          │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ ✅ HTTPS/TLS Termination        Effectiveness: 85%        │ ║
║  │ ✅ Security Groups              Effectiveness: 70%        │ ║
║  │ ✅ AWS Shield Standard          Effectiveness: 60%        │ ║
║  │ ✅ Access Logging               Effectiveness: 65%        │ ║
║  │ ✅ Health Checks                Effectiveness: 90%        │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ CONTROL GAPS                                               │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ ❌ AWS WAF Not Deployed         Risk Increase: +35%       │ ║
║  │ ❌ Rate Limiting Not Configured Risk Increase: +25%       │ ║
║  │ ❌ DDoS Response Plan Missing   Risk Increase: +20%       │ ║
║  │ ⚠️  Certificate Pinning Absent  Risk Increase: +15%       │ ║
║  │ ⚠️  Log Analysis Not Automated  Risk Increase: +10%       │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ TOP 3 ATTACK SCENARIOS                                     │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ 1. DDoS Layer 7 Attack                                     │ ║
║  │    Likelihood: HIGH  │  Impact: CRITICAL  │  Risk: 🔴      │ ║
║  │    Estimated Downtime: 2-4 hours                           │ ║
║  │    Financial Impact: $200,000                              │ ║
║  │                                                            │ ║
║  │ 2. Man-in-the-Middle via DNS Hijacking                     │ ║
║  │    Likelihood: MEDIUM  │  Impact: HIGH  │  Risk: 🟠       │ ║
║  │    Potential Data Leak: Session tokens                     │ ║
║  │    Financial Impact: $150,000                              │ ║
║  │                                                            │ ║
║  │ 3. Certificate Theft/Compromise                            │ ║
║  │    Likelihood: LOW  │  Impact: CRITICAL  │  Risk: 🟠      │ ║
║  │    Scope: All HTTPS traffic                                │ ║
║  │    Financial Impact: $500,000                              │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ RECOMMENDED MITIGATIONS                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ Priority 1 (Immediate - 7 days):                           │ ║
║  │   • Deploy AWS WAF with OWASP ruleset                      │ ║
║  │   • Configure rate limiting (1000 req/5min)                │ ║
║  │   • Enable detailed access logging                         │ ║
║  │   Cost: $2,500/month  │  Risk Reduction: 45%              │ ║
║  │                                                            │ ║
║  │ Priority 2 (Medium - 30 days):                             │ ║
║  │   • Implement AWS Shield Advanced                          │ ║
║  │   • Set up DDoS response runbook                           │ ║
║  │   • Deploy CloudFront in front of ALB                      │ ║
║  │   Cost: $3,500/month  │  Risk Reduction: 30%              │ ║
║  │                                                            │ ║
║  │ Priority 3 (Long-term - 90 days):                          │ ║
║  │   • Certificate transparency monitoring                    │ ║
║  │   • Implement HSTS headers                                 │ ║
║  │   • Automated log analysis with alerts                     │ ║
║  │   Cost: $1,000/month  │  Risk Reduction: 10%              │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  RESIDUAL RISK AFTER MITIGATIONS: 🟡 MEDIUM (Score: 40/100)    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Component Card: EC2/ECS Application Tier

```
╔══════════════════════════════════════════════════════════════════╗
║                  💻 EC2/ECS APPLICATION TIER                     ║
║                        THREAT CARD                               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  OVERALL RISK LEVEL: 🟠 HIGH (Score: 78/100)                    ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ COMPONENT DETAILS                                          │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ Name:            app-tier-instances                        │ ║
║  │ Type:            EC2 t3.medium / ECS Fargate               │ ║
║  │ Exposure:        🔒 Private Subnet Only                    │ ║
║  │ Data Handled:    Business Logic, User Sessions, API Keys   │ ║
║  │ Access:          Via ALB only                              │ ║
║  │ IAM Role:        ec2-app-role (MEDIUM PRIVILEGE)           │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ STRIDE THREAT BREAKDOWN                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  S - SPOOFING              🔴 CRITICAL                     │ ║
║  │      ████████████████████░  92/100                         │ ║
║  │      • SSRF to IMDS (IMDSv1 enabled!)                      │ ║
║  │      • Service Impersonation                               │ ║
║  │      • Process Injection                                   │ ║
║  │                                                            │ ║
║  │  T - TAMPERING             🟠 HIGH                         │ ║
║  │      █████████████████░░░  82/100                          │ ║
║  │      • Code Injection (SQLi, XSS)                          │ ║
║  │      • Malicious Dependencies                              │ ║
║  │      • Configuration Changes                               │ ║
║  │                                                            │ ║
║  │  R - REPUDIATION           🟡 MEDIUM                       │ ║
║  │      ██████████░░░░░░░░░░  55/100                          │ ║
║  │      • Insufficient Audit Logging                          │ ║
║  │      • No User Action Tracking                             │ ║
║  │                                                            │ ║
║  │  I - INFO DISCLOSURE       🔴 CRITICAL                     │ ║
║  │      ██████████████████░░  88/100                          │ ║
║  │      • Secrets in Environment Variables                    │ ║
║  │      • Memory Dumps                                        │ ║
║  │      • Verbose Error Messages                              │ ║
║  │      • Exposed Debug Endpoints                             │ ║
║  │                                                            │ ║
║  │  D - DENIAL OF SERVICE     🟠 HIGH                         │ ║
║  │      ██████████████░░░░░░  72/100                          │ ║
║  │      • Resource Exhaustion (CPU/Memory)                    │ ║
║  │      • Application Crashes                                 │ ║
║  │      • Infinite Loops                                      │ ║
║  │                                                            │ ║
║  │  E - ELEVATION             🔴 CRITICAL                     │ ║
║  │      ████████████████████░  90/100                         │ ║
║  │      • Container Escape                                    │ ║
║  │      • Privilege Escalation to Root                        │ ║
║  │      • IAM Role Assumption                                 │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ EXISTING CONTROLS                                          │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ ✅ Private Subnet Isolation     Effectiveness: 85%        │ ║
║  │ ✅ Security Groups              Effectiveness: 75%        │ ║
║  │ ⚠️  Non-root Containers         Effectiveness: 60%        │ ║
║  │ ⚠️  Basic IAM Roles             Effectiveness: 50%        │ ║
║  │ ❌ No Runtime Protection        Effectiveness: 0%         │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ CRITICAL VULNERABILITIES                                   │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │ 🔴 CVE-SSRF-IMDS: SSRF to Instance Metadata Service       │ ║
║  │    CVSS: 9.8 (Critical)                                    │ ║
║  │    Vector: Application accepts user-controlled URLs        │ ║
║  │    Impact: Full IAM credential theft                       │ ║
║  │    Mitigation: ❌ IMDSv2 NOT enforced                      │ ║
║  │    Remediation: Require IMDSv2 + Input validation          │ ║
║  │                                                            │ ║
║  │ 🔴 CVE-SQLI-001: SQL Injection in User Input               │ ║
║  │    CVSS: 9.1 (Critical)                                    │ ║
║  │    Vector: Unsanitized user input to database              │ ║
║  │    Impact: Full database compromise                        │ ║
║  │    Mitigation: ❌ Input validation NOT implemented         │ ║
║  │    Remediation: Prepared statements + WAF                  │ ║
║  │                                                            │ ║
║  │ 🟠 CVE-CONTAINER-ESC: Container Escape Vulnerability       │ ║
║  │    CVSS: 7.8 (High)                                        │ ║
║  │    Vector: Privileged container + kernel exploit           │ ║
║  │    Impact: Host compromise                                 │ ║
║  │    Mitigation: ⚠️  Containers run as non-root             │ ║
║  │    Remediation: AppArmor/SELinux profiles                  │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ ATTACK SURFACE ANALYSIS                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  Entry Points:                                             │ ║
║  │    • HTTP/HTTPS (from ALB)         Risk: 🔴 CRITICAL      │ ║
║  │    • Environment Variables         Risk: 🟠 HIGH          │ ║
║  │    • Third-party APIs              Risk: 🟡 MEDIUM        │ ║
║  │    • Package Dependencies          Risk: 🟡 MEDIUM        │ ║
║  │                                                            │ ║
║  │  Sensitive Data Processed:                                 │ ║
║  │    • User credentials              Storage: ❌ Plaintext  │ ║
║  │    • API keys                      Storage: ❌ Env vars   │ ║
║  │    • Session tokens                Storage: ⚠️  Memory    │ ║
║  │    • Customer PII                  Storage: ✅ Encrypted  │ ║
║  │                                                            │ ║
║  │  Network Connectivity:                                     │ ║
║  │    • RDS Database (3306)           Protocol: ❌ Unencrypt │ ║
║  │    • External APIs (443)           Protocol: ✅ TLS       │ ║
║  │    • AWS Services                  Protocol: ✅ HTTPS     │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ RECOMMENDED MITIGATIONS                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ 🔴 CRITICAL (Immediate - 72 hours):                        │ ║
║  │   1. Enforce IMDSv2 on all instances                       │ ║
║  │   2. Implement input validation framework                  │ ║
║  │   3. Move secrets to AWS Secrets Manager                   │ ║
║  │   4. Enable RDS SSL/TLS connections                        │ ║
║  │   Cost: $0 (config change)  │  Risk Reduction: 60%        │ ║
║  │                                                            │ ║
║  │ 🟠 HIGH (Within 7 days):                                   │ ║
║  │   5. Deploy runtime security (Falco/GuardDuty)             │ ║
║  │   6. Implement AppArmor/SELinux profiles                   │ ║
║  │   7. Add SAST scanning to CI/CD                            │ ║
║  │   8. Implement structured logging                          │ ║
║  │   Cost: $3,000/month  │  Risk Reduction: 25%              │ ║
║  │                                                            │ ║
║  │ 🟡 MEDIUM (Within 30 days):                                │ ║
║  │   9. Container image scanning                              │ ║
║  │  10. Dependency vulnerability scanning (SCA)               │ ║
║  │  11. Secrets rotation automation                           │ ║
║  │   Cost: $1,500/month  │  Risk Reduction: 10%              │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  RESIDUAL RISK AFTER MITIGATIONS: 🟡 MEDIUM (Score: 32/100)    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Component Card: RDS Database

```
╔══════════════════════════════════════════════════════════════════╗
║                      🗃️  RDS DATABASE                            ║
║                        THREAT CARD                               ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  OVERALL RISK LEVEL: 🔴 CRITICAL (Score: 92/100)                ║
║  ⚠️  CROWN JEWEL ASSET - HIGHEST PRIORITY                       ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ COMPONENT DETAILS                                          │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ Name:            production-mysql-db                       │ ║
║  │ Type:            RDS MySQL 8.0                             │ ║
║  │ Instance:        db.t3.large (2 vCPU, 8GB RAM)             │ ║
║  │ Exposure:        🔒 Data Subnet (Fully Isolated)           │ ║
║  │ Data:            🔴 CRITICAL - Customer PII, Payments      │ ║
║  │ Volume:          150,000 customer records                  │ ║
║  │ Encryption:      ⚠️  At-rest ONLY (KMS)                    │ ║
║  │ Backup:          ❌ Unencrypted snapshots                  │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ DATA CLASSIFICATION                                        │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  Customer PII:           🔴 CRITICAL                       │ ║
║  │    • Names, Emails       150,000 records                   │ ║
║  │    • Phone Numbers       150,000 records                   │ ║
║  │    • Addresses           120,000 records                   │ ║
║  │    • SSN/Tax IDs         85,000 records                    │ ║
║  │    Dark Web Value: $5-15 per record = $750K-$2.25M         │ ║
║  │                                                            │ ║
║  │  Payment Information:    🔴 CRITICAL (PCI DSS)             │ ║
║  │    • Credit Card Tokens  50,000 records                    │ ║
║  │    • Payment History     200,000 transactions              │ ║
║  │    Breach Fine: $100-500 per record = $5M-$25M             │ ║
║  │                                                            │ ║
║  │  Business Data:          🟠 HIGH                           │ ║
║  │    • Orders              500,000 records                   │ ║
║  │    • Product Catalog     50,000 items                      │ ║
║  │    Competitive Value: $1-2M                                │ ║
║  │                                                            │ ║
║  │  TOTAL BREACH IMPACT: $10M - $30M                          │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ STRIDE THREAT BREAKDOWN                                    │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  S - SPOOFING              🟠 HIGH                         │ ║
║  │      ████████████████░░░░  78/100                          │ ║
║  │      • Stolen DB Credentials (from app)                    │ ║
║  │      • IAM Role Assumption                                 │ ║
║  │      • Snapshot Access Theft                               │ ║
║  │                                                            │ ║
║  │  T - TAMPERING             🔴 CRITICAL                     │ ║
║  │      ██████████████████░░  85/100                          │ ║
║  │      • SQL Injection (via application)                     │ ║
║  │      • Direct Data Modification                            │ ║
║  │      • Backup Tampering                                    │ ║
║  │                                                            │ ║
║  │  R - REPUDIATION           🔴 CRITICAL                     │ ║
║  │      █████████████████████  98/100                         │ ║
║  │      • ❌ NO AUDIT LOGGING ENABLED                         │ ║
║  │      • Cannot prove unauthorized access                    │ ║
║  │      • No query tracking                                   │ ║
║  │                                                            │ ║
║  │  I - INFO DISCLOSURE       🔴 CRITICAL                     │ ║
║  │      █████████████████████  99/100                         │ ║
║  │      • Unencrypted snapshots (PUBLIC RISK!)                │ ║
║  │      • ❌ No TLS for connections                           │ ║
║  │      • Data Exfiltration via SQLi                          │ ║
║  │      • Memory dumps contain plaintext                      │ ║
║  │                                                            │ ║
║  │  D - DENIAL OF SERVICE     🟠 HIGH                         │ ║
║  │      ██████████████░░░░░░  68/100                          │ ║
║  │      • Storage Exhaustion                                  │ ║
║  │      • Connection Pool Exhaustion                          │ ║
║  │      • Resource-intensive Queries                          │ ║
║  │      • Snapshot Deletion                                   │ ║
║  │                                                            │ ║
║  │  E - ELEVATION             🟠 HIGH                         │ ║
║  │      ███████████████░░░░░  72/100                          │ ║
║  │      • SQL-based Privilege Escalation                      │ ║
║  │      • Master User Compromise                              │ ║
║  │      • IAM Policy Exploitation                             │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ COMPLIANCE VIOLATIONS                                      │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  ❌ GDPR Article 32: Security of Processing               │ ║
║  │     Violation: No audit logs, unencrypted transit          │ ║
║  │     Penalty: Up to €20M or 4% annual revenue              │ ║
║  │                                                            │ ║
║  │  ❌ PCI DSS Requirement 10: Log and Monitor                │ ║
║  │     Violation: No database activity monitoring             │ ║
║  │     Penalty: $5,000-$100,000 per month                    │ ║
║  │                                                            │ ║
║  │  ❌ SOC 2 CC6.1: Logical Access Controls                   │ ║
║  │     Violation: Insufficient access logging                 │ ║
║  │     Impact: Failed audit, customer churn                   │ ║
║  │                                                            │ ║
║  │  ⚠️  HIPAA (if applicable): Audit Controls                 │ ║
║  │     Violation: No audit trail                              │ ║
║  │     Penalty: $100-$50,000 per violation                   │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ EXISTING CONTROLS (INSUFFICIENT)                           │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │ ✅ KMS Encryption at Rest       Effectiveness: 70%        │ ║
║  │ ✅ Private Subnet Isolation     Effectiveness: 85%        │ ║
║  │ ✅ Security Group Restrictions  Effectiveness: 75%        │ ║
║  │ ⚠️  Automatic Backups           Effectiveness: 50%        │ ║
║  │ ❌ No Audit Logging             Effectiveness: 0%         │ ║
║  │ ❌ No Encryption in Transit     Effectiveness: 0%         │ ║
║  │ ❌ No Database Activity Monitor Effectiveness: 0%         │ ║
║  │ ❌ No Access Anomaly Detection  Effectiveness: 0%         │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ CRITICAL MITIGATIONS (REQUIRED IMMEDIATELY)                │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │ 🔴 PRIORITY 0 (Within 24 hours):                           │ ║
║  │   1. Enable RDS Enhanced Monitoring                        │ ║
║  │   2. Enable automated snapshot encryption                  │ ║
║  │   3. Audit existing snapshots for public exposure          │ ║
║  │   Cost: $50/month  │  Risk Reduction: 15%                 │ ║
║  │                                                            │ ║
║  │ 🔴 PRIORITY 1 (Within 72 hours):                           │ ║
║  │   4. Enable MySQL audit logging                            │ ║
║  │   5. Enforce SSL/TLS for all connections                   │ ║
║  │   6. Implement least-privilege DB users                    │ ║
║  │   7. Rotate all database credentials                       │ ║
║  │   Cost: $200/month  │  Risk Reduction: 40%                │ ║
║  │                                                            │ ║
║  │ 🟠 PRIORITY 2 (Within 7 days):                             │ ║
║  │   8. Deploy Database Activity Monitoring (DAM)             │ ║
║  │   9. Enable GuardDuty RDS Protection                       │ ║
║  │  10. Implement secrets rotation                            │ ║
║  │  11. Set up anomaly detection alerts                       │ ║
║  │   Cost: $1,500/month  │  Risk Reduction: 25%              │ ║
║  │                                                            │ ║
║  │ 🟡 PRIORITY 3 (Within 30 days):                            │ ║
║  │  12. Implement data masking for non-prod                   │ ║
║  │  13. Enable Multi-AZ for HA                                │ ║
║  │  14. Set up read replicas                                  │ ║
║  │  15. Implement query performance monitoring                │ ║
║  │   Cost: $800/month  │  Risk Reduction: 12%                │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  ┌────────────────────────────────────────────────────────────┐ ║
║  │ INCIDENT RESPONSE READINESS                                │ ║
║  ├────────────────────────────────────────────────────────────┤ ║
║  │                                                            │ ║
║  │  Detection Capability:        🔴 CRITICAL GAP (15%)       │ ║
║  │  Mean Time to Detect (MTTD):  45 days (UNACCEPTABLE)      │ ║
║  │  Mean Time to Respond (MTTR): Unknown (No runbook)        │ ║
║  │                                                            │ ║
║  │  Backup Recovery:             ⚠️  UNTESTED                │ ║
║  │  Last Recovery Test:          ❌ NEVER                     │ ║
║  │  RPO (Recovery Point):        24 hours                     │ ║
║  │  RTO (Recovery Time):         Unknown                      │ ║
║  │                                                            │ ║
║  │  Data Breach Notification:    ❌ NO PROCESS               │ ║
║  │  Forensics Capability:        ❌ NO AUDIT LOGS            │ ║
║  │  Legal Review Process:        ❌ NOT DEFINED              │ ║
║  │                                                            │ ║
║  └────────────────────────────────────────────────────────────┘ ║
║                                                                  ║
║  RESIDUAL RISK AFTER MITIGATIONS: 🟠 HIGH (Score: 48/100)      ║
║  ⚠️  Even with full mitigation, remains HIGH RISK asset        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

**Document Classification:** CONFIDENTIAL
**Version:** 2.0 (Visual Edition)
**Last Updated:** February 14, 2026
**Tool:** IriusRisk-style Component Threat Cards
