# Visual Architecture with Threat Overlay

## System Architecture with Security Threats

```mermaid
graph TB
    subgraph Internet["🌐 INTERNET (Untrusted Zone)"]
        User["👤 End User<br/>❗ SPOOFING<br/>❗ TAMPERING"]
        Attacker["🔴 Threat Actor<br/>• DDoS Attacks<br/>• SQL Injection<br/>• Credential Theft"]
    end

    subgraph VPC["🏢 AWS VPC (10.0.0.0/16)"]
        subgraph PublicSubnet["📡 PUBLIC SUBNET (DMZ)<br/>Risk Level: HIGH"]
            IGW["🚪 Internet Gateway<br/>✅ Public Access<br/>⚠️ Entry Point"]
            ALB["⚖️ Application Load Balancer<br/>🔴 CRITICAL THREATS:<br/>├─ S1: DNS Hijacking<br/>├─ T1: MITM Attack<br/>├─ I1: Certificate Theft<br/>└─ D1: DDoS Layer 7"]
            NAT["🔄 NAT Gateway<br/>✅ Outbound Only<br/>⚠️ Cost: $0.045/GB"]
        end

        subgraph PrivateSubnet["🔒 PRIVATE SUBNET (App Tier)<br/>Risk Level: MEDIUM"]
            EC2["💻 EC2/ECS Instances<br/>🔴 HIGH THREATS:<br/>├─ S1: SSRF to IMDS<br/>├─ T1: Code Injection<br/>├─ I1: Secret Exposure<br/>├─ E1: Container Escape<br/>└─ D1: Resource Exhaustion"]
            SG_APP["🛡️ Security Group<br/>Port 80/443 Only"]
        end

        subgraph DataSubnet["🗄️ DATA SUBNET (Isolated)<br/>Risk Level: CRITICAL"]
            RDS["🗃️ RDS Database<br/>🔴 CRITICAL THREATS:<br/>├─ S1: Credential Theft<br/>├─ T1: SQL Injection<br/>├─ I1: Data Exfiltration<br/>├─ R1: No Audit Logs<br/>└─ E1: Privilege Escalation"]
            SG_DB["🛡️ Security Group<br/>Port 3306 (MySQL Only)"]
        end
    end

    subgraph Monitoring["📊 MONITORING & LOGGING"]
        CW["📈 CloudWatch<br/>⚠️ Gap: No Real-time Alerts"]
        CT["📝 CloudTrail<br/>✅ API Logging Enabled"]
        VFL["🌊 VPC Flow Logs<br/>⚠️ Gap: Not Enabled"]
    end

    subgraph Security["🔐 SECURITY SERVICES"]
        WAF["🛡️ AWS WAF<br/>❌ NOT DEPLOYED<br/>🔴 CRITICAL GAP"]
        GD["👁️ GuardDuty<br/>❌ NOT ENABLED<br/>🔴 HIGH RISK"]
        SH["🛡️ AWS Shield<br/>✅ Standard (Free)"]
    end

    %% Data Flow
    User -->|"1. HTTPS Request"| IGW
    Attacker -.->|"Attack Vectors"| IGW
    IGW -->|"2. Route to ALB"| ALB
    ALB -->|"3. Forward to App<br/>🔴 No WAF Inspection"| EC2
    EC2 -->|"4. Database Query<br/>🔴 SQL Injection Risk"| RDS
    EC2 -->|"5. Outbound (Updates)"| NAT
    NAT -->|"6. Internet Access"| IGW

    %% Monitoring
    ALB -.->|"Access Logs"| CW
    EC2 -.->|"Application Logs"| CW
    RDS -.->|"⚠️ No Audit Logs"| CW
    VPC -.->|"❌ Flow Logs Disabled"| VFL

    %% Security
    ALB -.->|"❌ No Protection"| WAF
    EC2 -.->|"❌ No Threat Detection"| GD
    ALB -.->|"✅ DDoS Protected"| SH

    %% Styling
    classDef critical fill:#ff4444,stroke:#cc0000,stroke-width:3px,color:#fff
    classDef high fill:#ff9933,stroke:#cc6600,stroke-width:2px,color:#000
    classDef medium fill:#ffcc00,stroke:#cc9900,stroke-width:2px,color:#000
    classDef good fill:#44ff44,stroke:#00cc00,stroke-width:2px,color:#000
    classDef missing fill:#cccccc,stroke:#666666,stroke-width:2px,color:#000,stroke-dasharray: 5 5

    class RDS,ALB critical
    class EC2,NAT high
    class SG_APP,SG_DB medium
    class CT,SH good
    class WAF,GD,VFL missing
```

## Trust Boundary Map

```mermaid
graph LR
    subgraph TB1["🔴 TRUST BOUNDARY 1<br/>Internet ↔ VPC"]
        TB1_Threats["THREATS:<br/>• DDoS Attacks<br/>• Brute Force<br/>• Exploit Scanning<br/>• DNS Hijacking"]
        TB1_Controls["CONTROLS:<br/>✅ Security Groups<br/>✅ NACLs<br/>❌ WAF (Missing)<br/>❌ IDS/IPS"]
    end

    subgraph TB2["🟠 TRUST BOUNDARY 2<br/>Public ↔ Private Subnet"]
        TB2_Threats["THREATS:<br/>• Lateral Movement<br/>• Privilege Escalation<br/>• SSRF Attacks<br/>• Session Hijacking"]
        TB2_Controls["CONTROLS:<br/>✅ Security Groups<br/>✅ Private Subnets<br/>⚠️ No WAF<br/>⚠️ No Network Firewall"]
    end

    subgraph TB3["🟡 TRUST BOUNDARY 3<br/>App ↔ Database Subnet"]
        TB3_Threats["THREATS:<br/>• SQL Injection<br/>• Credential Theft<br/>• Data Exfiltration<br/>• Unauthorized Access"]
        TB3_Controls["CONTROLS:<br/>✅ Security Groups<br/>✅ Private Subnet<br/>❌ No DAM<br/>❌ No Encryption in Transit"]
    end

    TB1 -->|"Crossing"| TB2
    TB2 -->|"Crossing"| TB3
```

## Risk Heat Map by Component

```
┌─────────────────────────────────────────────────────────────────┐
│                    LIKELIHOOD vs IMPACT MATRIX                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  IMPACT                                                         │
│    ▲                                                            │
│    │                                                            │
│ C  │         RDS-I1 🔴         ALB-D1 🔴                        │
│ R  │       (Data Leak)        (DDoS Attack)                    │
│ I  │                                                            │
│ T  │    EC2-E1 🔴         EC2-S1 🔴                            │
│ I  │  (Container         (SSRF to                              │
│ C  │    Escape)           IMDS)                                │
│ A  │                                                            │
│ L  ├─────────────────────────────────────────────────────       │
│    │                                                            │
│    │                   ALB-T1 🟠      RDS-R1 🟠                │
│ H  │                   (MITM)      (No Audit)                  │
│ I  │                                                            │
│ G  │      EC2-I1 🟠                                            │
│ H  │   (Secret Leak)                                           │
│    │                                                            │
│    ├─────────────────────────────────────────────────────       │
│    │                                                            │
│ M  │                         NAT-D1 🟡                         │
│ E  │                        (Outage)                           │
│ D  │                                                            │
│    │         SG-T1 🟡                                          │
│    │      (Misconfig)                                          │
│    │                                                            │
│    ├─────────────────────────────────────────────────────       │
│    │                                                            │
│ L  │                                  IGW-S1 🟢                │
│ O  │                                (IP Spoof)                 │
│ W  │                                                            │
│    │                                                            │
│    └─────────────────────────────────────────────────────►     │
│         LOW      MEDIUM      HIGH      VERY HIGH               │
│                      LIKELIHOOD                                │
└─────────────────────────────────────────────────────────────────┘

Legend: 🔴 Critical  🟠 High  🟡 Medium  🟢 Low
```

## Attack Surface Visualization

```
                    ┌─────────────────────────┐
                    │   EXTERNAL ATTACKERS    │
                    │   • Nation States       │
                    │   • Cybercriminals      │
                    │   • Script Kiddies      │
                    └───────────┬─────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐      ┌────────────────┐     ┌────────────────┐
│  ATTACK       │      │   ATTACK       │     │   ATTACK       │
│  VECTOR 1:    │      │   VECTOR 2:    │     │   VECTOR 3:    │
│  Web App      │      │   API          │     │   CI/CD        │
│  🔴 CRITICAL  │      │   🟠 HIGH      │     │   🟠 HIGH      │
└───────┬───────┘      └────────┬───────┘     └────────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │  TARGET ASSETS        │
                    │  ├─ Customer PII      │
                    │  ├─ Payment Data      │
                    │  ├─ Business Data     │
                    │  └─ Infrastructure    │
                    └───────────────────────┘

ATTACK SURFACE SCORE: 78/100 (HIGH RISK)
├─ Public Endpoints: 3 (High)
├─ Authentication Points: 2 (Medium)
├─ Data Stores: 1 (Critical)
└─ Third-party Integrations: 0 (Low)
```

## Component Risk Scores

```
┌──────────────────────────────────────────────────────────────┐
│                     COMPONENT RISK SCORING                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ALB (Load Balancer)              ████████████░░  85/100    │
│  ├─ Exposure: Public              🔴 Critical               │
│  ├─ Controls: Partial             🟠 Insufficient           │
│  └─ Vulnerabilities: 8            🔴 High Count             │
│                                                              │
│  EC2/ECS (Application)            ███████████░░░  78/100    │
│  ├─ Exposure: Private             🟢 Good                   │
│  ├─ Controls: Moderate            🟡 Acceptable             │
│  └─ Vulnerabilities: 6            🟠 Medium Count           │
│                                                              │
│  RDS (Database)                   █████████████  92/100     │
│  ├─ Exposure: Isolated            🟢 Good                   │
│  ├─ Controls: Weak                🔴 Critical Gap           │
│  └─ Vulnerabilities: 10           🔴 Critical Count         │
│                                                              │
│  NAT Gateway                      ████░░░░░░░░░  35/100     │
│  ├─ Exposure: Public              🟠 Medium                 │
│  ├─ Controls: Good                🟢 Strong                 │
│  └─ Vulnerabilities: 2            🟢 Low Count              │
│                                                              │
│  Security Groups                  ██████░░░░░░░  48/100     │
│  ├─ Exposure: N/A                 ➖ Control Layer          │
│  ├─ Controls: Moderate            🟡 Acceptable             │
│  └─ Misconfigurations: 4          🟡 Medium Risk            │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Risk Calculation: (Exposure × 0.4) + (Control Gap × 0.4) + (Vuln Count × 0.2)
```

## Threat Actor Profiles

```mermaid
mindmap
  root((Threat<br/>Actors))
    External
      Nation State
        Sophistication: VERY HIGH
        Motivation: Espionage
        Target: Customer Data
        Capability: APT, Zero-days
      Cybercriminals
        Sophistication: HIGH
        Motivation: Financial
        Target: Payment Data
        Capability: Ransomware, Exfiltration
      Script Kiddies
        Sophistication: LOW
        Motivation: Fun/Fame
        Target: Public Services
        Capability: Known Exploits
    Internal
      Malicious Insider
        Sophistication: MEDIUM
        Motivation: Revenge/Financial
        Target: All Data
        Capability: Authorized Access
      Negligent Employee
        Sophistication: N/A
        Motivation: Unintentional
        Target: Credentials/Secrets
        Capability: Accidental Exposure
    Supply Chain
      Compromised Dependencies
        Sophistication: HIGH
        Motivation: Backdoor Access
        Target: Infrastructure
        Capability: Code Injection
      Third-party Breach
        Sophistication: VARIES
        Motivation: Lateral Movement
        Target: Shared Services
        Capability: Credential Reuse
```

---

**Document Classification:** CONFIDENTIAL
**Version:** 2.0 (Visual Edition)
**Last Updated:** February 14, 2026
**Tool:** IriusRisk-style Visual Threat Model
