# Attack Path Visualization

## Attack Path 1: Data Exfiltration via SQL Injection

```mermaid
graph TD
    Start["🎯 ATTACKER GOAL<br/>Steal Customer PII<br/>Value: $500K on Dark Web"]

    subgraph Phase1["🔍 RECONNAISSANCE"]
        Recon1["Scan Public ALB<br/>Tools: Nmap, Nessus"]
        Recon2["Identify SQL Endpoints<br/>Tools: Burp Suite, SQLMap"]
        Recon3["Test for SQL Injection<br/>Success: TRUE ⚠️"]
    end

    subgraph Phase2["🔓 INITIAL ACCESS"]
        Access1["Exploit SQLi Vulnerability<br/>Payload: ' OR '1'='1"]
        Access2["Bypass Input Validation<br/>Control: ❌ NOT PRESENT"]
        Access3["Bypass WAF<br/>Control: ❌ NOT DEPLOYED"]
    end

    subgraph Phase3["🎪 PRIVILEGE ESCALATION"]
        Priv1["Extract DB Credentials<br/>Method: UNION-based SQLi"]
        Priv2["Access RDS Directly<br/>Port: 3306 (MySQL)"]
        Priv3["Enumerate Tables<br/>Target: users, payments"]
    end

    subgraph Phase4["💾 DATA COLLECTION"]
        Data1["SELECT * FROM users<br/>Records: 100,000+"]
        Data2["SELECT * FROM payments<br/>Records: 50,000+"]
        Data3["Export to Temp File<br/>Location: /tmp/exfil.csv"]
    end

    subgraph Phase5["📤 EXFILTRATION"]
        Exfil1["DNS Tunneling<br/>Detection: ❌ NO DNS MONITORING"]
        Exfil2["HTTPS POST to C2<br/>Detection: ❌ NO DLP"]
        Exfil3["Data Successfully Stolen<br/>Impact: CRITICAL"]
    end

    subgraph Detection["🚨 DETECTION POINTS"]
        Det1["WAF - SQL Pattern<br/>Status: ❌ NOT DEPLOYED"]
        Det2["Database Activity Monitor<br/>Status: ❌ NOT DEPLOYED"]
        Det3["VPC Flow Logs<br/>Status: ❌ NOT ENABLED"]
        Det4["GuardDuty - Exfiltration<br/>Status: ❌ NOT ENABLED"]
    end

    Start --> Recon1
    Recon1 --> Recon2
    Recon2 --> Recon3
    Recon3 -->|"Vulnerability Found ✓"| Access1
    Access1 --> Access2
    Access2 --> Access3
    Access3 -->|"No Protection ⚠️"| Priv1
    Priv1 --> Priv2
    Priv2 --> Priv3
    Priv3 --> Data1
    Data1 --> Data2
    Data2 --> Data3
    Data3 --> Exfil1
    Exfil1 --> Exfil2
    Exfil2 --> Exfil3

    Access1 -.->|"❌ Missed"| Det1
    Priv2 -.->|"❌ Missed"| Det2
    Exfil1 -.->|"❌ Missed"| Det3
    Exfil2 -.->|"❌ Missed"| Det4

    classDef attacker fill:#ff4444,stroke:#cc0000,stroke-width:3px,color:#fff
    classDef recon fill:#ff9933,stroke:#cc6600,stroke-width:2px
    classDef access fill:#ffcc00,stroke:#cc9900,stroke-width:2px
    classDef impact fill:#cc00cc,stroke:#990099,stroke-width:2px
    classDef missed fill:#cccccc,stroke:#666666,stroke-width:2px,stroke-dasharray: 5 5

    class Start attacker
    class Recon1,Recon2,Recon3 recon
    class Access1,Access2,Access3 access
    class Exfil3 impact
    class Det1,Det2,Det3,Det4 missed
```

**Attack Complexity:** MEDIUM
**Time to Compromise:** 2-4 hours
**Skill Required:** Intermediate (Automated tools available)
**Detection Probability:** 15% (Very Low)
**Financial Impact:** $500,000 - $2,000,000

---

## Attack Path 2: SSRF to IMDS Credential Theft

```mermaid
graph TD
    Start2["🎯 ATTACKER GOAL<br/>Gain AWS IAM Credentials<br/>Pivot: Full Infrastructure Access"]

    subgraph Recon2["🔍 RECONNAISSANCE"]
        R1["Identify User Input Fields<br/>Target: URL/Image Upload"]
        R2["Test for SSRF<br/>Payload: http://169.254.169.254"]
        R3["Confirm IMDSv1 Active<br/>Response: 200 OK ⚠️"]
    end

    subgraph Exploit2["💥 EXPLOITATION"]
        E1["Access IMDS Endpoint<br/>URL: /latest/meta-data/"]
        E2["Enumerate IAM Roles<br/>Found: ec2-app-role"]
        E3["Retrieve Credentials<br/>Keys: AccessKey, SecretKey, Token"]
    end

    subgraph Pivot2["🔄 LATERAL MOVEMENT"]
        P1["Configure AWS CLI<br/>Profile: stolen-creds"]
        P2["Test Permissions<br/>Command: aws sts get-caller-identity"]
        P3["Enumerate Resources<br/>S3, RDS, EC2, Secrets"]
    end

    subgraph Impact2["💣 IMPACT"]
        I1["Access S3 Buckets<br/>Data: Customer Files"]
        I2["Read RDS Snapshots<br/>Data: Database Backups"]
        I3["Deploy Backdoor<br/>Persistence: Lambda Function"]
    end

    subgraph Controls2["🛡️ CONTROL GAPS"]
        C1["Input Validation<br/>Status: ❌ MISSING"]
        C2["IMDSv2 Enforcement<br/>Status: ❌ NOT REQUIRED"]
        C3["Network Egress Filtering<br/>Status: ❌ NOT DEPLOYED"]
        C4["GuardDuty Detection<br/>Status: ❌ NOT ENABLED"]
    end

    Start2 --> R1 --> R2 --> R3
    R3 -->|"SSRF Works ✓"| E1
    E1 --> E2 --> E3
    E3 -->|"Creds Stolen ⚠️"| P1
    P1 --> P2 --> P3
    P3 --> I1
    P3 --> I2
    P3 --> I3

    R2 -.->|"❌ Not Blocked"| C1
    E1 -.->|"❌ IMDSv1 Allowed"| C2
    E3 -.->|"❌ Not Filtered"| C3
    P1 -.->|"❌ Not Detected"| C4

    classDef goal fill:#ff4444,stroke:#cc0000,stroke-width:3px,color:#fff
    classDef step fill:#ff9933,stroke:#cc6600,stroke-width:2px
    classDef critical fill:#cc00cc,stroke:#990099,stroke-width:3px,color:#fff
    classDef gap fill:#cccccc,stroke:#666666,stroke-width:2px,stroke-dasharray: 5 5

    class Start2 goal
    class E3,P3 critical
    class C1,C2,C3,C4 gap
```

**Attack Complexity:** MEDIUM
**Time to Compromise:** 1-2 hours
**Skill Required:** Intermediate
**Detection Probability:** 20% (Low)
**Financial Impact:** $1,000,000+ (Full AWS Compromise)

---

## Attack Path 3: DDoS Against Application Load Balancer

```mermaid
graph LR
    subgraph Preparation["⚙️ PREPARATION"]
        Prep1["Rent Botnet<br/>Cost: $500/hour<br/>Capacity: 100 Gbps"]
        Prep2["Identify Target<br/>ALB DNS Name"]
        Prep3["Choose Attack Type<br/>HTTP Flood (Layer 7)"]
    end

    subgraph Attack["⚡ ATTACK EXECUTION"]
        Att1["Launch HTTP Flood<br/>Requests: 1M/sec"]
        Att2["Overwhelm ALB<br/>Status: 503 Errors"]
        Att3["Exhaust Backend<br/>EC2 CPU: 100%"]
    end

    subgraph Defense["🛡️ DEFENSE RESPONSE"]
        Def1["AWS Shield Standard<br/>Protection: Layer 3/4 Only"]
        Def2["WAF Rate Limiting<br/>Status: ❌ NOT DEPLOYED"]
        Def3["Auto Scaling<br/>Status: ⚠️ Too Slow"]
    end

    subgraph Impact3["💥 IMPACT"]
        Imp1["Service Unavailable<br/>Duration: 2-4 hours"]
        Imp2["Revenue Loss<br/>$50,000/hour"]
        Imp3["SLA Violation<br/>Penalty: $100,000"]
    end

    Prep1 --> Prep2 --> Prep3
    Prep3 --> Att1
    Att1 --> Att2
    Att2 --> Att3
    Att1 -.->|"✅ Partially Blocked"| Def1
    Att1 -.->|"❌ Not Protected"| Def2
    Att3 -.->|"⚠️ Insufficient"| Def3
    Att3 --> Imp1
    Imp1 --> Imp2
    Imp2 --> Imp3

    classDef prep fill:#4444ff,stroke:#0000cc,stroke-width:2px,color:#fff
    classDef attack fill:#ff4444,stroke:#cc0000,stroke-width:3px,color:#fff
    classDef defense fill:#44ff44,stroke:#00cc00,stroke-width:2px
    classDef impact fill:#cc00cc,stroke:#990099,stroke-width:2px,color:#fff

    class Prep1,Prep2,Prep3 prep
    class Att1,Att2,Att3 attack
    class Def1,Def2,Def3 defense
    class Imp1,Imp2,Imp3 impact
```

**Attack Complexity:** LOW (Botnet-as-a-Service)
**Time to Impact:** 15-30 minutes
**Skill Required:** Low (Script Kiddie)
**Detection Probability:** 95% (High - Obvious)
**Financial Impact:** $200,000 - $500,000

---

## Attack Path 4: Supply Chain Attack via CI/CD

```mermaid
sequenceDiagram
    actor Attacker
    participant GitHub as GitHub Repository
    participant Actions as GitHub Actions
    participant OIDC as AWS OIDC Provider
    participant IAM as IAM Role
    participant Terraform as Terraform
    participant VPC as Production VPC

    Note over Attacker: 🎯 Goal: Backdoor Infrastructure

    Attacker->>GitHub: 1. Phish Developer Credentials
    Note right of GitHub: ❌ Control Gap: No Hardware MFA

    Attacker->>GitHub: 2. Fork Repository Internally
    GitHub-->>Attacker: Repository Access Granted

    Attacker->>GitHub: 3. Modify Terraform Code<br/>(Add Backdoor IAM User)
    Note right of GitHub: ⚠️ Control: PR Review Required

    Attacker->>GitHub: 4. Social Engineer Reviewer
    GitHub-->>Actions: 5. Workflow Triggered
    Note right of Actions: ❌ Control Gap: No Code Signing

    Actions->>OIDC: 6. Request AWS Credentials
    OIDC-->>IAM: 7. Assume Role (sts:AssumeRoleWithWebIdentity)
    IAM-->>Actions: 8. Temporary Credentials

    Actions->>Terraform: 9. terraform apply
    Note right of Terraform: ❌ Control Gap: No Manual Approval

    Terraform->>VPC: 10. Create Backdoor User<br/>(backdoor-admin)
    VPC-->>Attacker: 11. Access Keys Extracted

    Note over Attacker: ✅ Persistent Access Achieved

    Attacker->>VPC: 12. Use Backdoor for<br/>Ongoing Access

    rect rgb(255, 200, 200)
        Note over GitHub,VPC: 🔴 CRITICAL: No detection until manual audit
    end
```

**Attack Timeline:**
```
Hour 0-24:   Phishing campaign, credential theft
Hour 24-48:  Reconnaissance, code exploration
Hour 48-72:  Malicious code crafted
Hour 72-96:  Social engineering for PR approval
Hour 96:     Backdoor deployed to production
Hour 96+:    Persistent unauthorized access

Detection Probability: 30% (Low-Medium)
Mean Time to Detect: 45 days
```

---

## Attack Kill Chain Visualization

```
┌────────────────────────────────────────────────────────────────────┐
│              LOCKHEED MARTIN CYBER KILL CHAIN                      │
│                  Applied to AWS VPC Infrastructure                 │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  1. RECONNAISSANCE                  🔴 High Risk                  │
│     ├─ Public ALB Enumeration       ✅ CloudFront could hide      │
│     ├─ DNS Enumeration              ✅ Private hosted zone        │
│     └─ Port Scanning                ❌ No IDS/IPS                 │
│                                                                    │
│  2. WEAPONIZATION                   🟠 Medium Risk                │
│     ├─ SQLi Payload Crafting        ⚠️ Automated tools exist      │
│     ├─ SSRF Exploit Development     ⚠️ POC publicly available     │
│     └─ Malware Development          ✅ Antivirus present          │
│                                                                    │
│  3. DELIVERY                        🔴 High Risk                  │
│     ├─ HTTP POST to Web App         ❌ No WAF                     │
│     ├─ Phishing Email               ⚠️ Some email filtering       │
│     └─ Supply Chain (npm)           ❌ No SCA scanning            │
│                                                                    │
│  4. EXPLOITATION                    🔴 Critical Risk              │
│     ├─ SQLi Execution               ❌ No input validation        │
│     ├─ SSRF to IMDS                 ❌ IMDSv1 enabled             │
│     └─ Container Escape             ⚠️ Non-root containers        │
│                                                                    │
│  5. INSTALLATION                    🟠 Medium Risk                │
│     ├─ Backdoor User Creation       ⚠️ CloudTrail logging         │
│     ├─ Persistence Lambda           ⚠️ Some IAM restrictions      │
│     └─ Cryptominer Deployment       ❌ No runtime monitoring      │
│                                                                    │
│  6. COMMAND & CONTROL               🟠 Medium Risk                │
│     ├─ DNS Tunneling                ❌ No DNS monitoring          │
│     ├─ HTTPS C2 Channel             ❌ No SSL inspection          │
│     └─ Tor Exit Node                ❌ No network monitoring      │
│                                                                    │
│  7. ACTIONS ON OBJECTIVES           🔴 Critical Risk              │
│     ├─ Data Exfiltration            ❌ No DLP                     │
│     ├─ Ransomware Deployment        ⚠️ Backups exist             │
│     └─ Service Destruction          ⚠️ CloudTrail alerts          │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

OVERALL KILL CHAIN RESISTANCE: 35/100 (HIGH VULNERABILITY)

Defense in Depth Score:
├─ Network Layer:     45/100 (Insufficient)
├─ Application Layer: 25/100 (Critical Gaps)
├─ Data Layer:        40/100 (Major Gaps)
└─ Detection Layer:   20/100 (Minimal Coverage)
```

## Threat Progression Timeline

```mermaid
gantt
    title Attack Progression Over Time (Typical SQL Injection Attack)
    dateFormat HH:mm
    axisFormat %H:%M

    section Reconnaissance
    Port Scanning           :recon1, 00:00, 30m
    Service Enumeration     :recon2, after recon1, 45m
    Vulnerability Scanning  :recon3, after recon2, 60m

    section Exploitation
    SQLi Testing           :exploit1, after recon3, 30m
    Bypass Attempts        :exploit2, after exploit1, 45m
    Successful Injection   :crit, exploit3, after exploit2, 15m

    section Privilege Escalation
    DB Enumeration         :priv1, after exploit3, 20m
    Extract Credentials    :priv2, after priv1, 15m
    Escalate Privileges    :crit, priv3, after priv2, 10m

    section Data Exfiltration
    Locate Sensitive Data  :exfil1, after priv3, 30m
    Stage Data             :exfil2, after exfil1, 20m
    Exfiltrate Data        :crit, exfil3, after exfil2, 45m

    section Covering Tracks
    Delete Logs            :cover1, after exfil3, 15m
    Remove Evidence        :cover2, after cover1, 10m
```

**Total Time to Compromise: 4-6 hours**
**Detection Windows:**
- ✅ Reconnaissance Phase: 60% detection probability (if IDS deployed)
- ⚠️ Exploitation Phase: 25% detection probability (if WAF deployed)
- ❌ Exfiltration Phase: 10% detection probability (minimal monitoring)

---

**Document Classification:** CONFIDENTIAL
**Version:** 2.0 (Visual Edition)
**Last Updated:** February 14, 2026
**Tool:** IriusRisk-style Attack Path Analysis
