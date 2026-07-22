# AWS VPC Infrastructure - Visual Architecture Diagram

## Complete Infrastructure Topology with Threat Annotations

```

    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃                                                                                                                         ┃
    ┃                                         🌐  INTERNET  (Untrusted Zone)                                                 ┃
    ┃                                                                                                                         ┃
    ┃    ╔═══════════════╗          ╔═══════════════╗          ╔═══════════════╗          ╔═══════════════╗                  ┃
    ┃    ║      👤       ║          ║      🔓       ║          ║      👨‍💼       ║          ║      🔥       ║                  ┃
    ┃    ║   End User    ║          ║   Attacker    ║          ║    Remote     ║          ║   Network     ║                  ┃
    ┃    ║   (Browser)   ║          ║  (Threat)     ║          ║   Developer   ║          ║   Firewall    ║                  ┃
    ┃    ║               ║          ║               ║          ║   (VPN)       ║          ║               ║                  ┃
    ┃    ║ 🔴 Spoofing   ║          ║ 🔴 DDoS       ║          ║ ✅ MFA Auth   ║          ║ ⚠️ External   ║                  ┃
    ┃    ║ 🔴 MITM       ║          ║ 🔴 Exploits   ║          ║ ✅ Encrypted  ║          ║ ⚠️ Basic Rules║                  ┃
    ┃    ╚═══════╦═══════╝          ╚═══════╦═══════╝          ╚═══════╦═══════╝          ╚═══════╦═══════╝                  ┃
    ┃            ║                          ║                          ║                          ║                          ┃
    ┗━━━━━━━━━━━━╬━━━━━━━━━━━━━━━━━━━━━━━━━━╬━━━━━━━━━━━━━━━━━━━━━━━━━━╬━━━━━━━━━━━━━━━━━━━━━━━━━━╬━━━━━━━━━━━━━━━━━━━━━━┛
                 ║                          ║                          ║                          ║
                 ║                          ║                          ║                          ║
                 ╚═══════════════╦══════════╩═══════════════╦══════════╩═════════╦════════════════╝
                                 ║                          ║                    ║
                                 ║  HTTPS (443)             ║                    ║
                                 ║  HTTP (80→443)           ║                    ║
                                 ║                          ║                    ║
                ╔════════════════╩══════════════════════════╩════════════════════╩══════════════════════════════════════╗
                ║                                                                                                       ║
                ║                          ══════ TRUST BOUNDARY 1: Internet → AWS Cloud ══════                        ║
                ║                                         🔴 HIGH RISK ZONE                                            ║
                ║                         Controls: TLS, Shield Standard ❌ WAF Missing                                ║
                ║                                                                                                       ║
                ╚════════════════╦══════════════════════════════════════════════════════════════════════════════════════╝
                                 ║
                                 ▼
    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃                                                                                                                         ┃
    ┃                                       ☁️  AWS CLOUD - VPC (10.0.0.0/16)                                               ┃
    ┃                                            Region: us-east-1                                                           ┃
    ┃                                                                                                                         ┃
    ┃    ┌─────────────────────────────────────────────────────────────────────────────────────────────────────────────┐     ┃
    ┃    │                                                                                                             │     ┃
    ┃    │                             📍 PUBLIC SUBNET (10.0.1.0/24) - AZ: us-east-1a                                 │     ┃
    ┃    │                                                                                                             │     ┃
    ┃    │    ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ║                          🚪  INTERNET GATEWAY (igw-vpc-001)                                   ║        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ║  ┌─────────────────────────────────────────────────────────────────────────────────────┐     ║        │     ┃
    ┃    │    ║  │  Route Table: 0.0.0.0/0 → Internet                                                  │     ║        │     ┃
    ┃    │    ║  │  Status: ✅ Active                                                                  │     ║        │     ┃
    ┃    │    ║  │  Threats: 🔴 DDoS Entry Point  🟠 IP Spoofing (Mitigated by NACLs)                │     ║        │     ┃
    ┃    │    ║  └─────────────────────────────────────────────────────────────────────────────────────┘     ║        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ╚═══════════════════════════════════════╦═══════════════════════════════════════════════╝        │     ┃
    ┃    │                                            ║                                                         │     ┃
    ┃    │                                            ║ All Internet Traffic                                    │     ┃
    ┃    │                                            ▼                                                         │     ┃
    ┃    │    ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ║                    ⚖️  APPLICATION LOAD BALANCER (production-alb)                             ║        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓     ║        │     ┃
    ┃    │    ║  ┃  DNS: app.example.com                                                             ┃     ║        │     ┃
    ┃    │    ║  ┃  Scheme: internet-facing                                                          ┃     ║        │     ┃
    ┃    │    ║  ┃  IP Type: IPv4                                                                    ┃     ║        │     ┃
    ┃    │    ║  ┃                                                                                   ┃     ║        │     ┃
    ┃    │    ║  ┃  Listeners:                                                                       ┃     ║        │     ┃
    ┃    │    ║  ┃  ├─ 🔓 HTTP:80  → ↪️  Redirect to HTTPS:443                                      ┃     ║        │     ┃
    ┃    │    ║  ┃  └─ 🔐 HTTPS:443 → 🎯 Target Group (app-tier-tg)                                 ┃     ║        │     ┃
    ┃    │    ║  ┃                                                                                   ┃     ║        │     ┃
    ┃    │    ║  ┃  TLS Certificate: ✅ ACM (Auto-renewal enabled)                                  ┃     ║        │     ┃
    ┃    │    ║  ┃  TLS Policy: ELBSecurityPolicy-TLS-1-2-2017-01                                   ┃     ║        │     ┃
    ┃    │    ║  ┃                                                                                   ┃     ║        │     ┃
    ┃    │    ║  ┃  Health Checks: ✅ /health endpoint (30s interval)                               ┃     ║        │     ┃
    ┃    │    ║  ┃  Access Logs: ✅ S3 Bucket (alb-logs-bucket)                                     ┃     ║        │     ┃
    ┃    │    ║  ┃  Deletion Protection: ✅ Enabled                                                 ┃     ║        │     ┃
    ┃    │    ║  ┃                                                                                   ┃     ║        │     ┃
    ┃    │    ║  ┃  🔴 CRITICAL THREATS:                                                            ┃     ║        │     ┃
    ┃    │    ║  ┃  • DDoS Layer 7 Attack (No WAF!) ━━━━━━━━━━━━━━━━━━━━ Risk: 95/100 🔴           ┃     ║        │     ┃
    ┃    │    ║  ┃  • SQL Injection (Passes to backend) ━━━━━━━━━━━━━━━ Risk: 90/100 🔴           ┃     ║        │     ┃
    ┃    │    ║  ┃  • Man-in-the-Middle Attack ━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 75/100 🟠           ┃     ║        │     ┃
    ┃    │    ║  ┃  • DNS Hijacking ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 70/100 🟠           ┃     ║        │     ┃
    ┃    │    ║  ┃  • Certificate Theft/Compromise ━━━━━━━━━━━━━━━━━━━━ Risk: 65/100 🟠           ┃     ║        │     ┃
    ┃    │    ║  ┃                                                                                   ┃     ║        │     ┃
    ┃    │    ║  ┃  ❌ MISSING CONTROLS:                                                            ┃     ║        │     ┃
    ┃    │    ║  ┃  • AWS WAF (Web Application Firewall)                                            ┃     ║        │     ┃
    ┃    │    ║  ┃  • Rate Limiting Rules                                                           ┃     ║        │     ┃
    ┃    │    ║  ┃  • Geo-blocking / IP Reputation Lists                                            ┃     ║        │     ┃
    ┃    │    ║  ┃  • DDoS Response Runbook                                                         ┃     ║        │     ┃
    ┃    │    ║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛     ║        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ║  ┌─────────────────────────────────────────────────────────────────────────────────────┐     ║        │     ┃
    ┃    │    ║  │  🛡️  Security Group: alb-sg-001                                                    │     ║        │     ┃
    ┃    │    ║  │  Inbound:  0.0.0.0/0 → Port 80 (HTTP)                                              │     ║        │     ┃
    ┃    │    ║  │            0.0.0.0/0 → Port 443 (HTTPS)                                            │     ║        │     ┃
    ┃    │    ║  │  Outbound: app-sg-001 → Port 80, 443                                               │     ║        │     ┃
    ┃    │    ║  └─────────────────────────────────────────────────────────────────────────────────────┘     ║        │     ┃
    ┃    │    ║                                                                                               ║        │     ┃
    ┃    │    ╚═══════════════════════════════════════╦═══════════════════════════════════════════════╝        │     ┃
    ┃    │                                            ║                                                         │     ┃
    ┃    │                                            ║                                                         │     ┃
    ┃    │    ╔═══════════════════════════════════════╩═══════════════════════════════════════════════╗        │     ┃
    ┃    │    ║                                                                                        ║        │     ┃
    ┃    │    ║                      🔄  NAT GATEWAY (nat-gw-001)                                      ║        │     ┃
    ┃    │    ║                                                                                        ║        │     ┃
    ┃    │    ║  ┌──────────────────────────────────────────────────────────────────────────────┐     ║        │     ┃
    ┃    │    ║  │  Purpose: Outbound internet for private subnet instances                     │     ║        │     ┃
    ┃    │    ║  │  Elastic IP: ✅ Allocated                                                    │     ║        │     ┃
    ┃    │    ║  │  Used For: Package updates, External API calls                               │     ║        │     ┃
    ┃    │    ║  │  Cost: ~$0.045/GB data processed                                             │     ║        │     ┃
    ┃    │    ║  │  Threats: 🟡 Outage (Single AZ)  🟡 Data Exfiltration Channel               │     ║        │     ┃
    ┃    │    ║  └──────────────────────────────────────────────────────────────────────────────┘     ║        │     ┃
    ┃    │    ║                                                                                        ║        │     ┃
    ┃    │    ╚════════════════════════════════════════════════════════════════════════════════╝        │     ┃
    ┃    │                                                                                             │     ┃
    ┃    └─────────────────────────────────────────────────────────────────────────────────────────────┘     ┃
    ┃                                            ║                                                            ┃
    ┃                                            ║ HTTP/HTTPS                                                 ┃
    ┃    ╔════════════════════════════════════════╩════════════════════════════════════════════════════╗     ┃
    ┃    ║                                                                                              ║     ┃
    ┃    ║               ══════ TRUST BOUNDARY 2: Public Subnet → Private Subnet ══════                ║     ┃
    ┃    ║                                    🟠 MEDIUM RISK ZONE                                       ║     ┃
    ┃    ║                   Controls: Security Groups, Private Subnets ⚠️ No WAF                      ║     ┃
    ┃    ║                                                                                              ║     ┃
    ┃    ╚════════════════════════════════════════╦════════════════════════════════════════════════════╝     ┃
    ┃                                             ▼                                                           ┃
    ┃    ┌─────────────────────────────────────────────────────────────────────────────────────────────┐     ┃
    ┃    │                                                                                             │     ┃
    ┃    │                    📍 PRIVATE SUBNET (10.0.2.0/24, 10.0.3.0/24) - AZ: us-east-1a/1b        │     ┃
    ┃    │                                                                                             │     ┃
    ┃    │    ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗    │     ┃
    ┃    │    ║                                                                                               ║    │     ┃
    ┃    │    ║              💻  EC2 / ECS APPLICATION TIER (app-tier-instances)                              ║    │     ┃
    ┃    │    ║                                                                                               ║    │     ┃
    ┃    │    ║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   ┃  ║    │     ┃
    ┃    │    ║  ┃  │  💻 Instance 1  │  │  💻 Instance 2  │  │  💻 Instance 3  │  │  💻 Instance N  │   ┃  ║    │     ┃
    ┃    │    ║  ┃  │   t3.medium     │  │   t3.medium     │  │   t3.medium     │  │   t3.medium     │   ┃  ║    │     ┃
    ┃    │    ║  ┃  │   AZ: 1a        │  │   AZ: 1b        │  │   AZ: 1a        │  │   AZ: 1b        │   ┃  ║    │     ┃
    ┃    │    ║  ┃  │   IP: 10.0.2.10 │  │   IP: 10.0.3.10 │  │   IP: 10.0.2.11 │  │   IP: 10.0.3.11 │   ┃  ║    │     ┃
    ┃    │    ║  ┃  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘   ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  Instance Type: t3.medium (2 vCPU, 4 GB RAM)                                           ┃  ║    │     ┃
    ┃    │    ║  ┃  OS: Amazon Linux 2 / Ubuntu 22.04                                                     ┃  ║    │     ┃
    ┃    │    ║  ┃  Container Runtime: Docker 24.0 / ECS Fargate                                          ┃  ║    │     ┃
    ┃    │    ║  ┃  Auto Scaling: ✅ Enabled (Min: 2, Desired: 4, Max: 10)                               ┃  ║    │     ┃
    ┃    │    ║  ┃  IAM Role: ec2-app-role (S3 Read, RDS Connect, CloudWatch Logs)                       ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  📦 Application Stack:                                                                 ┃  ║    │     ┃
    ┃    │    ║  ┃  ├─ Web Framework: Flask/Django/Express.js                                             ┃  ║    │     ┃
    ┃    │    ║  ┃  ├─ Business Logic: Python/Node.js                                                     ┃  ║    │     ┃
    ┃    │    ║  ┃  ├─ Database Driver: MySQL Connector                                                   ┃  ║    │     ┃
    ┃    │    ║  ┃  ├─ Session Store: In-memory / Redis                                                   ┃  ║    │     ┃
    ┃    │    ║  ┃  └─ Logging: CloudWatch Logs Agent                                                     ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  🔴 CRITICAL THREATS:                                                                  ┃  ║    │     ┃
    ┃    │    ║  ┃  • SSRF to IMDS (IMDSv1 Enabled!) ━━━━━━━━━━━━━━━━━━━ Risk: 92/100 🔴                 ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Attack: http://169.254.169.254/latest/meta-data/iam/security-credentials/        ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Impact: Full IAM role credential theft                                            ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  • SQL Injection via User Input ━━━━━━━━━━━━━━━━━━━━━ Risk: 90/100 🔴                 ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Vector: Unvalidated form inputs, query parameters                                 ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Impact: Database compromise, data exfiltration                                     ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  • Secrets in Environment Variables ━━━━━━━━━━━━━━━━━ Risk: 88/100 🔴                 ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ DB_PASSWORD, API_KEYS in plaintext env vars                                       ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Impact: Credential exposure via /proc or container escape                         ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  • Container Escape ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 78/100 🟠                 ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Kernel exploits, privileged containers                                            ┃  ║    │     ┃
    ┃    │    ║  ┃    ↳ Impact: Host compromise, lateral movement                                         ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  • Code Injection (XSS, Template Injection) ━━━━━━━━━ Risk: 75/100 🟠                 ┃  ║    │     ┃
    ┃    │    ║  ┃  • Resource Exhaustion (CPU/Memory Bomb) ━━━━━━━━━━━━ Risk: 65/100 🟠                 ┃  ║    │     ┃
    ┃    │    ║  ┃  • Verbose Error Messages (Info Disclosure) ━━━━━━━━━ Risk: 55/100 🟡                 ┃  ║    │     ┃
    ┃    │    ║  ┃                                                                                         ┃  ║    │     ┃
    ┃    │    ║  ┃  ❌ MISSING CONTROLS:                                                                  ┃  ║    │     ┃
    ┃    │    ║  ┃  • IMDSv2 Enforcement (CRITICAL!)                                                      ┃  ║    │     ┃
    ┃    │    ║  ┃  • Input Validation Framework                                                          ┃  ║    │     ┃
    ┃    │    ║  ┃  • AWS Secrets Manager Integration                                                     ┃  ║    │     ┃
    ┃    │    ║  ┃  • AppArmor/SELinux Profiles                                                           ┃  ║    │     ┃
    ┃    │    ║  ┃  • Runtime Security Monitoring (Falco/GuardDuty Runtime)                               ┃  ║    │     ┃
    ┃    │    ║  ┃  • Container Image Scanning                                                            ┃  ║    │     ┃
    ┃    │    ║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ║    │     ┃
    ┃    │    ║                                                                                               ║    │     ┃
    ┃    │    ║  ┌─────────────────────────────────────────────────────────────────────────────────────┐     ║    │     ┃
    ┃    │    ║  │  🛡️  Security Group: app-sg-001                                                      │     ║    │     ┃
    ┃    │    ║  │  Inbound:  alb-sg-001 → Port 80 (HTTP)                                                │     ║    │     ┃
    ┃    │    ║  │            alb-sg-001 → Port 443 (HTTPS)                                              │     ║    │     ┃
    ┃    │    ║  │  Outbound: db-sg-001 → Port 3306 (MySQL)                                              │     ║    │     ┃
    ┃    │    ║  │            0.0.0.0/0 → Port 443 (HTTPS - for updates/APIs via NAT)                    │     ║    │     ┃
    ┃    │    ║  └─────────────────────────────────────────────────────────────────────────────────────┘     ║    │     ┃
    ┃    │    ║                                                                                               ║    │     ┃
    ┃    │    ╚═══════════════════════════════════════╦═══════════════════════════════════════════════════════╝    │     ┃
    ┃    │                                            ║                                                             │     ┃
    ┃    └────────────────────────────────────────────┼─────────────────────────────────────────────────────────────┘     ┃
    ┃                                                 ║                                                                   ┃
    ┃                                                 ║ MySQL Protocol (Port 3306)                                        ┃
    ┃                                                 ║ ❌ UNENCRYPTED (CRITICAL!)                                        ┃
    ┃    ╔════════════════════════════════════════════╩════════════════════════════════════════════════════╗             ┃
    ┃    ║                                                                                                  ║             ┃
    ┃    ║            ══════ TRUST BOUNDARY 3: Private Subnet → Data Subnet ══════                         ║             ┃
    ┃    ║                                 🔴 CRITICAL RISK ZONE                                            ║             ┃
    ┃    ║              Controls: Security Groups ❌ No Encryption ❌ No Audit Logs                         ║             ┃
    ┃    ║                                                                                                  ║             ┃
    ┃    ╚════════════════════════════════════════════╦════════════════════════════════════════════════════╝             ┃
    ┃                                                 ▼                                                                   ┃
    ┃    ┌─────────────────────────────────────────────────────────────────────────────────────────────┐                 ┃
    ┃    │                                                                                             │                 ┃
    ┃    │                     📍 DATA SUBNET (10.0.4.0/24, 10.0.5.0/24) - AZ: us-east-1a/1b          │                 ┃
    ┃    │                                                                                             │                 ┃
    ┃    │    ╔═══════════════════════════════════════════════════════════════════════════════════════════════╗          │                 ┃
    ┃    │    ║                                                                                               ║          │                 ┃
    ┃    │    ║                    🗃️  RDS MYSQL DATABASE (production-mysql-db)                               ║          │                 ┃
    ┃    │    ║                              🏆 CROWN JEWEL ASSET                                             ║          │                 ┃
    ┃    │    ║                                                                                               ║          │                 ┃
    ┃    │    ║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  ┌────────────────────────────────────────────────────────────────────────────────┐    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  🔧 DATABASE CONFIGURATION                                                     │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  ├────────────────────────────────────────────────────────────────────────────────┤    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Engine: MySQL 8.0.35                                                          │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Instance Class: db.t3.large (2 vCPU, 8 GB RAM)                               │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Storage: 100 GB GP3 SSD (Encrypted with KMS)                                 │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Multi-AZ: ❌ Disabled (Single Point of Failure!)                             │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Endpoint: production-mysql-db.abc123.us-east-1.rds.amazonaws.com:3306        │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  Publicly Accessible: ❌ No (Good!)                                            │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  └────────────────────────────────────────────────────────────────────────────────┘    ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  ┌────────────────────────────────────────────────────────────────────────────────┐    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  💾 DATA STORED (SENSITIVE)                                                    │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  ├────────────────────────────────────────────────────────────────────────────────┤    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  📊 Customer PII: 150,000 records                                              │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Full Names, Email Addresses, Phone Numbers                               │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Physical Addresses (120,000 records)                                     │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • SSN / Tax IDs (85,000 records)                                           │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Date of Birth, Gender                                                    │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │                                                                                │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  💳 Payment Information: 50,000 records                                        │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Tokenized Credit Card Data (PCI DSS Scope)                              │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Payment Transaction History (200,000 transactions)                       │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Billing Addresses                                                        │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │                                                                                │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  📦 Business Data: 500,000 records                                             │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Order History, Product Catalog, User Preferences                         │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │                                                                                │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │  💰 BREACH VALUATION:                                                          │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Dark Web Value: $750K - $2.25M (PII records)                             │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • GDPR Fines: Up to €20M or 4% annual revenue                             │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • PCI DSS Fines: $5,000 - $100,000/month                                   │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  │     • Total Breach Impact: $10M - $30M                                         │    ┃  ║          │                 ┃
    ┃    │    ║  ┃  └────────────────────────────────────────────────────────────────────────────────┘    ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  🔴 CRITICAL THREATS (Risk Score: 92/100):                                             ┃  ║          │                 ┃
    ┃    │    ║  ┃  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  1. ❌ NO AUDIT LOGGING (CRITICAL!) ━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 98/100 🔴        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Cannot detect unauthorized access                                                ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Cannot prove/disprove data breach                                                ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Compliance violation (GDPR, PCI DSS, SOC 2)                                      ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Mean Time to Detect (MTTD): 45 days (Industry avg: 3-5 days)                     ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  2. ❌ UNENCRYPTED DATABASE CONNECTIONS ━━━━━━━━━━━━━━━━━━━━━ Risk: 95/100 🔴        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • All data transmitted in CLEARTEXT between EC2 ↔ RDS                              ┃  ║          │                 ┃
    ┃    │    ║  ┃     • PII, passwords, payment data visible on network                                  ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Vulnerable to packet sniffing (if attacker gains network access)                 ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Compliance violation (PCI DSS Requirement 4)                                      ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  3. SQL INJECTION EXECUTION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 90/100 🔴        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • No WAF → malicious SQL reaches application                                       ┃  ║          │                 ┃
    ┃    │    ║  ┃     • No input validation → SQL injection succeeds                                     ┃  ║          │                 ┃
    ┃    │    ║  ┃     • No DAM → attack goes undetected                                                  ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Impact: Full database dump, data modification, deletion                          ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  4. ❌ UNENCRYPTED SNAPSHOTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 85/100 🔴        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Daily automated snapshots NOT encrypted                                          ┃  ║          │                 ┃
    ┃    │    ║  ┃     • If shared publicly (misconfiguration): Full data exposure                        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Snapshot location: S3 (same region)                                              ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  5. CREDENTIAL THEFT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 78/100 🟠        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • DB password in EC2 environment variables                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Container escape → credential access                                             ┃  ║          │                 ┃
    ┃    │    ║  ┃     • No secrets rotation policy                                                       ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  6. PRIVILEGE ESCALATION ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 72/100 🟠        ┃  ║          │                 ┃
    ┃    │    ║  ┃     • UNION-based SQL injection → access mysql.user table                              ┃  ║          │                 ┃
    ┃    │    ║  ┃     • Potential to create new DB admin users                                           ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  7. CONNECTION POOL EXHAUSTION (DoS) ━━━━━━━━━━━━━━━━━━━━━━ Risk: 68/100 🟠        ┃  ║          │                 ┃
    ┃    │    ║  ┃  8. DATA EXFILTRATION (No DLP) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━ Risk: 65/100 🟠        ┃  ║          │                 ┃
    ┃    │    ║  ┃                                                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  ❌ MISSING CRITICAL CONTROLS:                                                         ┃  ║          │                 ┃
    ┃    │    ║  ┃  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ┃  ║          │                 ┃
    ┃    │    ║  ┃  • MySQL Audit Plugin (Server Audit / MariaDB Audit Plugin)                            ┃  ║          │                 ┃
    ┃    │    ║  ┃  • SSL/TLS Connection Enforcement (require_secure_transport=ON)                        ┃  ║          │                 ┃
    ┃    │    ║  ┃  • Database Activity Monitoring (Imperva DAM, DataSunrise, etc.)                       ┃  ║          │                 ┃
    ┃    │    ║  ┃  • Snapshot Encryption (copy-db-snapshot with --kms-key-id)                            ┃  ║          │                 ┃
    ┃    │    ║  ┃  • GuardDuty RDS Protection (Anomaly detection)                                        ┃  ║          │                 ┃
    ┃    │    ║  ┃  • Multi-AZ Deployment (High availability)                                             ┃  ║          │                 ┃
    ┃    │    ║  ┃  • Read Replicas (Performance + DR)                                                    ┃  ║          │                 ┃
    ┃    │    ║  ┃  • Automated Backup Testing (Restore drill)                                            ┃  ║          │                 ┃
    ┃    │    ║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛  ║          │                 ┃
    ┃    │    ║                                                                                               ║          │                 ┃
    ┃    │    ║  ┌─────────────────────────────────────────────────────────────────────────────────────┐     ║          │                 ┃
    ┃    │    ║  │  🛡️  Security Group: db-sg-001                                                      │     ║          │                 ┃
    ┃    │    ║  │  Inbound:  app-sg-001 → Port 3306 (MySQL) ✅ RESTRICTED                             │     ║          │                 ┃
    ┃    │    ║  │  Outbound: NONE (Database doesn't initiate outbound) ✅                              │     ║          │                 ┃
    ┃    │    ║  │  Public Access: ❌ DENIED ✅ Good!                                                   │     ║          │                 ┃
    ┃    │    ║  └─────────────────────────────────────────────────────────────────────────────────────┘     ║          │                 ┃
    ┃    │    ║                                                                                               ║          │                 ┃
    ┃    │    ║  ┌─────────────────────────────────────────────────────────────────────────────────────┐     ║          │                 ┃
    ┃    │    ║  │  ⚙️  BACKUP & RECOVERY                                                               │     ║          │                 ┃
    ┃    │    ║  │  • Automated Backups: ✅ Daily at 03:00 UTC                                          │     ║          │                 ┃
    ┃    │    ║  │  • Retention Period: 7 days                                                          │     ║          │                 ┃
    ┃    │    ║  │  • Backup Window: 03:00-04:00 UTC                                                    │     ║          │                 ┃
    ┃    │    ║  │  • Point-in-Time Recovery: ✅ Enabled (last 7 days)                                 │     ║          │                 ┃
    ┃    │    ║  │  • Snapshot Encryption: ❌ NOT ENABLED (CRITICAL!)                                  │     ║          │                 ┃
    ┃    │    ║  │  • Last Restore Test: ❌ NEVER (CRITICAL!)                                          │     ║          │                 ┃
    ┃    │    ║  │  • RPO (Recovery Point): 24 hours                                                    │     ║          │                 ┃
    ┃    │    ║  │  • RTO (Recovery Time): Unknown (untested)                                           │     ║          │                 ┃
    ┃    │    ║  └─────────────────────────────────────────────────────────────────────────────────────┘     ║          │                 ┃
    ┃    │    ║                                                                                               ║          │                 ┃
    ┃    │    ╚═══════════════════════════════════════════════════════════════════════════════════════════════╝          │                 ┃
    ┃    │                                                                                                                │                 ┃
    ┃    └────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘                 ┃
    ┃                                                                                                                                        ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛



    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃                                                                                                                         ┃
    ┃                                     🔧  AWS SHARED SERVICES & MANAGEMENT                                               ┃
    ┃                                                                                                                         ┃
    ┃    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗              ┃
    ┃    ║   🔐 KMS      ║    ║  🔒 Secrets   ║    ║  ⚙️ Parameter ║    ║   📦 S3       ║    ║   🎫 ACM      ║              ┃
    ┃    ║  Key Mgmt Svc ║    ║   Manager     ║    ║    Store      ║    ║   Storage     ║    ║  Certificate  ║              ┃
    ┃    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣              ┃
    ┃    ║ ✅ RDS Keys   ║    ║ ❌ NOT USED   ║    ║ ✅ App Config ║    ║ ✅ ALB Logs   ║    ║ ✅ TLS Certs  ║              ┃
    ┃    ║ ✅ S3 Keys    ║    ║ (CRITICAL!)   ║    ║ • Non-secret  ║    ║ ✅ Backups    ║    ║ ✅ Auto       ║              ┃
    ┃    ║ ✅ EBS Keys   ║    ║ Should store: ║    ║   values      ║    ║ ✅ Snapshots  ║    ║   Renewal     ║              ┃
    ┃    ║ • aws/rds     ║    ║ • DB Password ║    ║ ⚠️ Some       ║    ║ ✅ Encrypted  ║    ║ • Wildcard    ║              ┃
    ┃    ║ • aws/s3      ║    ║ • API Keys    ║    ║   secrets     ║    ║ • Versioning  ║    ║ *.example.com ║              ┃
    ┃    ║               ║    ║ • Encryption  ║    ║   here (bad!) ║    ║ • Lifecycle   ║    ║               ║              ┃
    ┃    ║ Risk: 🟢 LOW  ║    ║ Risk: 🔴 HIGH ║    ║ Risk: 🟡 MED  ║    ║ Risk: 🟢 LOW  ║    ║ Risk: 🟢 LOW  ║              ┃
    ┃    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝              ┃
    ┃                                                                                                                         ┃
    ┃    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗              ┃
    ┃    ║  🌐 Route 53  ║    ║ 📊 CloudWatch ║    ║ 📝 CloudTrail ║    ║ 🌊 VPC Flow   ║    ║ 👁️ GuardDuty  ║              ┃
    ┃    ║   DNS Service ║    ║   Monitoring  ║    ║   Audit Logs  ║    ║    Logs       ║    ║  Threat Det   ║              ┃
    ┃    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣              ┃
    ┃    ║ ✅ Hosted     ║    ║ ⚠️ Partial    ║    ║ ✅ All API    ║    ║ ❌ NOT        ║    ║ ❌ NOT        ║              ┃
    ┃    ║   Zones       ║    ║   Coverage    ║    ║   Calls       ║    ║   ENABLED     ║    ║   ENABLED     ║              ┃
    ┃    ║ ✅ Health     ║    ║ • ALB Metrics ║    ║ ✅ All Regions║    ║ (CRITICAL!)   ║    ║ (CRITICAL!)   ║              ┃
    ┃    ║   Checks      ║    ║ • EC2 Metrics ║    ║ ✅ S3 Logs    ║    ║               ║    ║               ║              ┃
    ┃    ║ ⚠️ No DNSSEC  ║    ║ • App Logs    ║    ║ ✅ Validation ║    ║ Missing:      ║    ║ Missing:      ║              ┃
    ┃    ║               ║    ║ ❌ DB Logs    ║    ║ ⚠️ Manual     ║    ║ • Network     ║    ║ • Anomaly     ║              ┃
    ┃    ║               ║    ║   (Gap!)      ║    ║   Review      ║    ║   Visibility  ║    ║   Detection   ║              ┃
    ┃    ║ Risk: 🟡 MED  ║    ║ Risk: 🟠 HIGH ║    ║ Risk: 🟡 MED  ║    ║ Risk: 🔴 CRIT ║    ║ Risk: 🔴 CRIT ║              ┃
    ┃    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝              ┃
    ┃                                                                                                                         ┃
    ┃    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗    ╔═══════════════╗              ┃
    ┃    ║ 🛡️ AWS WAF    ║    ║ 🔰 Shield     ║    ║ 🔍 Security   ║    ║ 🎯 Systems    ║    ║ 🏭 CloudFormn ║              ┃
    ┃    ║  Web App FW   ║    ║  DDoS Protect ║    ║    Hub        ║    ║   Manager     ║    ║  IaC Service  ║              ┃
    ┃    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣    ╠═══════════════╣              ┃
    ┃    ║ ❌ NOT        ║    ║ ✅ Standard   ║    ║ ❌ NOT        ║    ║ ⚠️ Basic      ║    ║ ❌ NOT USED   ║              ┃
    ┃    ║   DEPLOYED    ║    ║   (Free)      ║    ║   ENABLED     ║    ║   Usage       ║    ║ (Use Terraform║              ┃
    ┃    ║ (CRITICAL!)   ║    ║ • Layer 3/4   ║    ║ (CRITICAL!)   ║    ║ • Patch Mgmt  ║    ║   instead)    ║              ┃
    ┃    ║               ║    ║ • ALB         ║    ║               ║    ║ • Run Command ║    ║               ║              ┃
    ┃    ║ Missing:      ║    ║ ⚠️ No Advanced║    ║ Missing:      ║    ║ ❌ No Auto    ║    ║ Terraform:    ║              ┃
    ┃    ║ • SQLi Rules  ║    ║   (Layer 7)   ║    ║ • Centralized ║    ║   Patching    ║    ║ ✅ Used for   ║              ┃
    ┃    ║ • XSS Rules   ║    ║ • $3K/month   ║    ║   Findings    ║    ║   (Gap!)      ║    ║   Deployments ║              ┃
    ┃    ║ • Rate Limit  ║    ║               ║    ║ • Compliance  ║    ║               ║    ║               ║              ┃
    ┃    ║ Risk: 🔴 CRIT ║    ║ Risk: 🟠 HIGH ║    ║ Risk: 🔴 CRIT ║    ║ Risk: 🟠 HIGH ║    ║ Risk: 🟢 LOW  ║              ┃
    ┃    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝    ╚═══════════════╝              ┃
    ┃                                                                                                                         ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛


    ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    ┃                                                                                                                         ┃
    ┃                                         🏢  CI/CD & DEPLOYMENT PIPELINE                                                ┃
    ┃                                              (GitHub Actions + AWS OIDC)                                               ┃
    ┃                                                                                                                         ┃
    ┃    ╔═══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗   ┃
    ┃    ║                                                                                                               ║   ┃
    ┃    ║                                    🐙  GITHUB PLATFORM                                                        ║   ┃
    ┃    ║                                                                                                               ║   ┃
    ┃    ║    ┏━━━━━━━━━━━━━━━━━━━━━┓        ┏━━━━━━━━━━━━━━━━━━━━━┓        ┏━━━━━━━━━━━━━━━━━━━━━┓                    ║   ┃
    ┃    ║    ┃  📁 Repository       ┃        ┃  ⚙️ GitHub Actions   ┃        ┃  🔐 GitHub Secrets  ┃                    ║   ┃
    ┃    ║    ┃  (Source Code)       ┃        ┃  (Workflows)         ┃        ┃  (Encrypted)        ┃                    ║   ┃
    ┃    ║    ┣━━━━━━━━━━━━━━━━━━━━━┫        ┣━━━━━━━━━━━━━━━━━━━━━┫        ┣━━━━━━━━━━━━━━━━━━━━━┫                    ║   ┃
    ┃    ║    ┃ • Terraform Code     ┃───────▶┃ 1. Checkout Code     ┃───────▶┃ • AWS_ROLE_ARN      ┃                    ║   ┃
    ┃    ║    ┃ • Application Source ┃        ┃ 2. KICS Security Scan┃        ┃ • AWS_REGION        ┃                    ║   ┃
    ┃    ║    ┃ • Workflow Files     ┃        ┃ 3. terraform plan    ┃        ┃ • GITHUB_TOKEN      ┃                    ║   ┃
    ┃    ║    ┃ • Infrastructure     ┃        ┃ 4. terraform apply   ┃        ┃ ✅ No DB Password!  ┃                    ║   ┃
    ┃    ║    ┃                      ┃        ┃ 5. Deploy to AWS     ┃        ┃ ✅ No AWS Keys!     ┃                    ║   ┃
    ┃    ║    ┃                      ┃        ┃                      ┃        ┃                     ┃                    ║   ┃
    ┃    ║    ┃ ✅ Branch Protection ┃        ┃ 🔴 THREATS:          ┃        ┃ ⚠️ Secret Masking   ┃                    ║   ┃
    ┃    ║    ┃ ✅ CODEOWNERS        ┃        ┃ • Supply Chain       ┃        ┃   (Logs only)       ┃                    ║   ┃
    ┃    ║    ┃ ✅ MFA Required      ┃        ┃ • Compromised Action ┃        ┃                     ┃                    ║   ┃
    ┃    ║    ┃ ✅ 2 PR Reviewers    ┃        ┃ • Malicious Workflow ┃        ┃ Risk: 🟡 MEDIUM     ┃                    ║   ┃
    ┃    ║    ┃ ⚠️ No Signed Commits ┃        ┃ • Secret Leak        ┃        ┃                     ┃                    ║   ┃
    ┃    ║    ┃                      ┃        ┃                      ┃        ┃                     ┃                    ║   ┃
    ┃    ║    ┃ Risk: 🟡 MEDIUM      ┃        ┃ Risk: 🟠 HIGH        ┃        ┗━━━━━━━━━━━━━━━━━━━━━┛                    ║   ┃
    ┃    ║    ┗━━━━━━━━━━━━━━━━━━━━━┛        ┗━━━━━━━━━╦━━━━━━━━━━━━┛                                                   ║   ┃
    ┃    ║                                              ║                                                                 ║   ┃
    ┃    ║                                              ║ OIDC Token (JWT)                                                ║   ┃
    ┃    ║                                              ▼                                                                 ║   ┃
    ┃    ║                                    ┏━━━━━━━━━━━━━━━━━━━━━┓                                                    ║   ┃
    ┃    ║                                    ┃  🔑 AWS IAM OIDC     ┃                                                    ║   ┃
    ┃    ║                                    ┃     Provider         ┃                                                    ║   ┃
    ┃    ║                                    ┣━━━━━━━━━━━━━━━━━━━━━┫                                                    ║   ┃
    ┃    ║                                    ┃ • github-oidc-role   ┃                                                    ║   ┃
    ┃    ║                                    ┃ • Temp Credentials   ┃                                                    ║   ┃
    ┃    ║                                    ┃ • Scoped to Repo     ┃                                                    ║   ┃
    ┃    ║                                    ┃ • 1 hour TTL         ┃                                                    ║   ┃
    ┃    ║                                    ┃                      ┃                                                    ║   ┃
    ┃    ║                                    ┃ ✅ No Static Keys    ┃                                                    ║   ┃
    ┃    ║                                    ┃ ✅ Auto Rotation     ┃                                                    ║   ┃
    ┃    ║                                    ┃                      ┃                                                    ║   ┃
    ┃    ║                                    ┃ Risk: 🟢 LOW         ┃                                                    ║   ┃
    ┃    ║                                    ┗━━━━━━━━━╦━━━━━━━━━━━┛                                                    ║   ┃
    ┃    ║                                              ║                                                                 ║   ┃
    ┃    ║                                              ║ Deploy Infrastructure                                           ║   ┃
    ┃    ║                                              ▼                                                                 ║   ┃
    ┃    ║                                    [ Creates VPC, ALB, EC2, RDS ]                                              ║   ┃
    ┃    ║                                                                                                               ║   ┃
    ┃    ╚═══════════════════════════════════════════════════════════════════════════════════════════════════════════════╝   ┃
    ┃                                                                                                                         ┃
    ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Summary Legend

```
╔══════════════════════════════════════════════════════════════╗
║                    VISUAL LEGEND                             ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ZONES & BOUNDARIES:                                         ║
║  ━━━━━━━━━━━━━━━━━━                                         ║
║  ┏━━━┓  External/Internet Zone (Untrusted)                  ║
║  ┃   ┃  AWS Cloud Boundary                                  ║
║  ┗━━━┛                                                       ║
║                                                              ║
║  ┌───┐  Internal Subnets (Trusted zones)                    ║
║  │   │  Public / Private / Data Subnets                     ║
║  └───┘                                                       ║
║                                                              ║
║  ╔═══╗  Component/Service Containers                        ║
║  ║   ║  Individual AWS services                             ║
║  ╚═══╝                                                       ║
║                                                              ║
║  RISK INDICATORS:                                            ║
║  ════════════════                                            ║
║  🔴 CRITICAL Risk (90-100)  - Immediate action required     ║
║  🟠 HIGH Risk     (70-89)   - Action within 7 days          ║
║  🟡 MEDIUM Risk   (40-69)   - Action within 30 days         ║
║  🟢 LOW Risk      (0-39)    - Action within 90 days         ║
║                                                              ║
║  STATUS SYMBOLS:                                             ║
║  ═══════════════                                             ║
║  ✅  Implemented / Enabled                                  ║
║  ❌  Not Implemented / Critical Gap                         ║
║  ⚠️   Partial Implementation / Warning                      ║
║  🏆  Crown Jewel Asset (High Value Target)                  ║
║                                                              ║
║  DATA FLOW:                                                  ║
║  ══════════                                                  ║
║  ───▶  Standard connection                                  ║
║  ═══▶  Encrypted connection                                 ║
║  ║     Vertical flow                                        ║
║  ═     Double line = trust boundary                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

## Component Overview

| Component | Instance | Risk Score | Status | Critical Issues |
|-----------|----------|------------|--------|-----------------|
| **Internet Gateway** | igw-vpc-001 | 45/100 🟡 | ✅ Active | DDoS entry point |
| **Application Load Balancer** | production-alb | 85/100 🔴 | ✅ Active | ❌ No WAF, ❌ No rate limiting |
| **NAT Gateway** | nat-gw-001 | 35/100 🟢 | ✅ Active | Single AZ (availability risk) |
| **EC2/ECS Application** | app-tier (2-10) | 78/100 🟠 | ✅ Active | ❌ IMDSv1, ❌ Secrets in env vars |
| **RDS MySQL Database** | production-mysql-db | 92/100 🔴 | ✅ Active | ❌ No audit logs, ❌ Unencrypted transit |
| **AWS WAF** | N/A | N/A | ❌ Not Deployed | Critical gap |
| **GuardDuty** | N/A | N/A | ❌ Not Enabled | No threat detection |
| **VPC Flow Logs** | N/A | N/A | ❌ Not Enabled | No network visibility |

---

**Document Classification:** CONFIDENTIAL
**Version:** 3.0 (Enhanced Visual Architecture)
**Last Updated:** February 14, 2026
**Tool:** IriusRisk-Style Visual Threat Model
**Owner:** DevSecOps Team
