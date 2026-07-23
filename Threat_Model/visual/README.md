# Visual Threat Model (IriusRisk-Style)

## Overview

This directory contains comprehensive visual threat modeling documentation for the VPC infrastructure, created using an IriusRisk-inspired approach. These visualizations provide graphical, easy-to-understand representations of security threats, risks, and controls.

## 📁 Files in This Directory

### 1. [architecture-threat-overlay.md](architecture-threat-overlay.md)
**Visual Architecture with Security Threats**

- **Purpose:** Shows the complete AWS VPC architecture with threats overlaid on each component
- **Key Features:**
  - Mermaid diagram with trust boundaries
  - Color-coded risk levels (Critical/High/Medium/Low)
  - Component-specific threat annotations
  - Risk heat map visualization
  - Attack surface analysis
  - Threat actor profiles (mind map)
- **Use Case:** Executive presentations, architecture reviews, onboarding new team members
- **Viewable In:** GitHub, VS Code (with Mermaid extension), Markdown Preview Enhanced

---

### 2. [attack-path-visualization.md](attack-path-visualization.md)
**Attack Path Analysis**

- **Purpose:** Visual representation of how attackers can compromise the infrastructure
- **Key Features:**
  - 4 complete attack scenarios with step-by-step flows
  - Mermaid sequence diagrams for attack chains
  - Detection point identification (and gaps)
  - Attack complexity and timeline analysis
  - Cyber Kill Chain mapping to infrastructure
  - Gantt chart showing attack progression over time
- **Attack Paths Covered:**
  1. Data exfiltration via SQL injection
  2. SSRF to IMDS credential theft
  3. DDoS against Application Load Balancer
  4. Supply chain attack via CI/CD compromise
- **Use Case:** Red team exercises, security training, penetration testing planning

---

### 3. [component-threat-cards.md](component-threat-cards.md)
**Detailed Component Security Cards**

- **Purpose:** In-depth threat analysis for each infrastructure component
- **Components Analyzed:**
  1. **Application Load Balancer (ALB)** - Risk: 85/100 (Critical)
  2. **EC2/ECS Application Tier** - Risk: 78/100 (High)
  3. **RDS Database** - Risk: 92/100 (Critical)
- **Each Card Contains:**
  - STRIDE threat breakdown with severity scores
  - Existing controls and effectiveness ratings
  - Critical vulnerabilities (CVE-style)
  - Attack surface analysis
  - Top 3 attack scenarios
  - Recommended mitigations (prioritized)
  - Residual risk after mitigation
  - Compliance violations
  - Financial impact estimates
- **Use Case:** Deep-dive security reviews, control gap analysis, remediation planning

---

### 4. [risk-dashboard.md](risk-dashboard.md)
**Executive Risk Dashboard**

- **Purpose:** High-level view of overall security posture and risk metrics
- **Key Visualizations:**
  - Risk distribution pie chart (Critical/High/Medium/Low)
  - Risk trend analysis (6-month view)
  - Financial impact analysis with ROI calculations
  - Comprehensive risk heat map (Likelihood × Impact)
  - Compliance status dashboard (GDPR, PCI DSS, SOC 2, HIPAA)
  - Security maturity model assessment
  - Priority action plan with Gantt chart
- **Metrics Included:**
  - Overall risk score: 72/100 (High Risk)
  - Total potential breach cost: $18M - $63M
  - Security investment needed: $90K/year
  - ROI on security investment: 6,300% - 22,300%
- **Use Case:** Board presentations, C-suite briefings, budget justification

---

### 5. [control-effectiveness-matrix.md](control-effectiveness-matrix.md)
**Security Control Analysis**

- **Purpose:** Evaluate the effectiveness of existing and missing security controls
- **Key Sections:**
  - Defense in Depth analysis (7 layers)
  - STRIDE threat to control mapping
  - Control effectiveness by category (Preventive/Detective/Corrective/Compensating/Deterrent)
  - Control gap priority matrix (Impact vs Effort)
  - ROI analysis by control
  - Control testing and validation status
- **Key Insights:**
  - Overall control effectiveness: 62/100 (Moderate)
  - Coverage gaps: 38% of attack surface unprotected
  - Preventive controls: 68% effective
  - Detective controls: 42% effective (CRITICAL GAP)
  - Logging coverage: 44% (CRITICAL GAP)
- **Use Case:** Security program assessment, control selection, investment prioritization

---

### 6. [data-flow-threats.md](data-flow-threats.md)
**Data Flow with Threat Mapping**

- **Purpose:** Map specific threats to each data flow in the architecture
- **Key Features:**
  - Mermaid sequence diagram showing user request flow with threats
  - 5 critical data flows analyzed:
    1. Internet → ALB (Public entry point)
    2. ALB → EC2/ECS (Application tier)
    3. EC2/ECS → RDS (Database access)
    4. EC2/ECS → AWS Services (Metadata, S3, Secrets)
    5. RDS → S3 (Backups and exports)
  - Threat identification for each flow with severity ratings
  - Monitoring and logging coverage visualization
  - Attack detection timeline comparison (current vs. proposed)
  - Mean Time to Detect (MTTD) analysis
- **Critical Finding:**
  - Current MTTD: 45 days
  - Proposed MTTD: 1 minute (with full controls)
  - Risk reduction: 99.97%
- **Use Case:** Data flow analysis, monitoring strategy, incident response planning

---

## 🎨 Visualization Technologies Used

### Mermaid Diagrams
All diagrams use Mermaid markdown syntax, which renders as graphics in:
- GitHub (native support)
- VS Code (with Mermaid Preview extension)
- GitLab
- Markdown Preview Enhanced
- Many modern markdown viewers

**Diagram Types:**
- `graph TB/LR` - Architecture diagrams, attack trees
- `sequenceDiagram` - Attack paths, data flows
- `pie` - Risk distribution
- `gantt` - Remediation timelines, attack progression
- `radar-chart` - Control effectiveness
- `mindmap` - Threat actor profiles

### ASCII Art / Box Drawing
Enhanced visual elements using:
- Unicode box-drawing characters (═ ║ ╔ ╗ ╚ ╝ ├ ┤)
- Progress bars (████░░░░)
- Status indicators (✅ ❌ ⚠️ 🔴 🟠 🟡 🟢)
- Tables and matrices

## 📊 How to View These Files

### Option 1: GitHub (Recommended)
1. Navigate to this folder on GitHub
2. Click on any `.md` file
3. Mermaid diagrams will render automatically
4. Color coding and emojis display properly

### Option 2: VS Code
1. Install "Markdown Preview Mermaid Support" extension
2. Open any `.md` file
3. Press `Ctrl+Shift+V` (Windows/Linux) or `Cmd+Shift+V` (Mac)
4. Mermaid diagrams render in preview pane

### Option 3: Export to PDF/HTML
```bash
# Using markdown-pdf (install first: npm install -g markdown-pdf)
markdown-pdf architecture-threat-overlay.md

# Using pandoc (install first: apt-get install pandoc)
pandoc risk-dashboard.md -o risk-dashboard.pdf

# Using Mermaid CLI (best quality)
npm install -g @mermaid-js/mermaid-cli
mmdc -i architecture-threat-overlay.md -o architecture.pdf
```

## 🎯 Recommended Reading Order

### For Executives / Leadership
1. **risk-dashboard.md** - Overall security posture and ROI
2. **architecture-threat-overlay.md** - High-level visual overview
3. **component-threat-cards.md** (RDS section only) - Crown jewel asset risk

### For Security Team
1. **architecture-threat-overlay.md** - Understand the landscape
2. **attack-path-visualization.md** - Know the attack vectors
3. **component-threat-cards.md** - Deep dive on each component
4. **control-effectiveness-matrix.md** - Identify control gaps
5. **data-flow-threats.md** - Understand data flow risks

### For Development Team
1. **data-flow-threats.md** - Understand application-level threats
2. **component-threat-cards.md** (EC2/ECS section) - Application security
3. **attack-path-visualization.md** (SQL Injection, SSRF) - Common attack vectors

### For Compliance / Audit
1. **risk-dashboard.md** (Compliance section) - Regulatory status
2. **component-threat-cards.md** (RDS compliance violations) - Data protection gaps
3. **control-effectiveness-matrix.md** - Control testing status

## 🔑 Key Findings Summary

### Critical Risks (Immediate Action Required)
| Risk | Component | Score | Impact |
|------|-----------|-------|--------|
| Unencrypted Database Connections | RDS | 99/100 | $18M-$63M |
| No Database Audit Logging | RDS | 98/100 | Compliance violation |
| SSRF to IMDSv1 | EC2/ECS | 92/100 | IAM credential theft |
| No WAF Deployment | ALB | 90/100 | Layer 7 attacks |
| SQL Injection Vulnerability | All | 85/100 | Data breach |

### Investment Required
- **Immediate (7 days):** $15,000 setup + $3,000/month
- **Medium-term (30 days):** $10,000 setup + $4,500/month
- **Long-term (90 days):** $5,000 setup + $2,500/month
- **Total Annual Cost:** $120,000

### ROI Calculation
- **Current Annual Risk:** $6.67M - $23.55M
- **Risk Reduction:** 85%
- **Residual Annual Risk:** $1M - $3.5M
- **Net Benefit:** $5.67M - $20.05M
- **Return on Investment:** 6,300% - 22,300%

## 📞 Contact Information

**Threat Model Owner:** DevSecOps Team
**Last Updated:** February 14, 2026
**Next Review:** May 14, 2026 (Quarterly)
**Version:** 2.0 (IriusRisk Visual Edition)

## 🔄 Updates and Maintenance

This threat model should be reviewed and updated:
- ✅ **Quarterly:** Scheduled review (Q2, Q3, Q4, Q1)
- ✅ **After major architecture changes:** New services, new data flows
- ✅ **After security incidents:** Lessons learned, new threats identified
- ✅ **When new threats emerge:** CVEs, attack techniques, threat intelligence
- ✅ **During compliance audits:** External findings, regulatory changes

## 📚 Additional Resources

- **Original Threat Model:** [../models/vpc-threat-model.md](../models/vpc-threat-model.md)
- **STRIDE Reference:** [../docs/stride-reference.md](../docs/stride-reference.md)
- **Attack Trees:** [../diagrams/attack-trees.md](../diagrams/attack-trees.md)
- **Findings Summary:** [../docs/findings-summary.md](../docs/findings-summary.md)

---

**Classification:** CONFIDENTIAL
**Distribution:** Internal Security Team, Leadership, Compliance
**Retention:** 7 years (compliance requirement)
