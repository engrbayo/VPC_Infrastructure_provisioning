# Threat Model: Secure VPC Infrastructure

## Overview

This threat model analyzes the security posture of the AWS VPC infrastructure deployed using Terraform. The analysis follows the STRIDE methodology to identify potential threats, assess risks, and document mitigations.

## Purpose

- **Identify security risks** before they become incidents
- **Document security controls** and their effectiveness
- **Provide actionable recommendations** for security improvements
- **Establish a baseline** for continuous security assessment

## Scope

### In Scope
- VPC architecture (multi-tier design)
- CI/CD pipeline (GitHub Actions + Terraform)
- IAM roles and policies
- Data flows between components
- Network security controls
- Logging and monitoring infrastructure

### Out of Scope
- Application-level code (focus on infrastructure)
- Third-party SaaS integrations
- End-user device security
- Physical security

## System Under Analysis

**Project:** secure-vpc
**Environment:** Multi-environment (dev, staging, prod)
**Cloud Provider:** AWS
**Region:** us-east-1
**IaC Tool:** Terraform
**CI/CD:** GitHub Actions

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ═════════════════╪═════════════════  TRUST BOUNDARY 1
                         │
                    ┌────▼────┐
                    │   ALB   │  (Public Subnet)
                    └────┬────┘
                         │
        ═════════════════╪═════════════════  TRUST BOUNDARY 2
                         │
                    ┌────▼────┐
                    │   APP   │  (Private Subnet)
                    └────┬────┘
                         │
        ═════════════════╪═════════════════  TRUST BOUNDARY 3
                         │
                    ┌────▼────┐
                    │   RDS   │  (Data Subnet)
                    └─────────┘
```

## Key Assets

| Asset | Criticality | Description |
|-------|-------------|-------------|
| Customer Data (RDS) | CRITICAL | PII, financial data, credentials |
| Application Secrets | HIGH | API keys, DB passwords, tokens |
| Infrastructure Code | HIGH | Terraform state, AWS credentials |
| Network Configuration | MEDIUM | VPC, subnets, routing rules |
| Audit Logs | HIGH | CloudWatch, VPC Flow Logs, CloudTrail |

## Threat Actors

### External Attackers
- **Motivation:** Data theft, ransom, disruption
- **Capability:** Medium to High
- **Access:** Internet-facing resources only

### Malicious Insiders
- **Motivation:** Data exfiltration, sabotage
- **Capability:** High (has legitimate access)
- **Access:** AWS console, GitHub, CI/CD

### Supply Chain Attackers
- **Motivation:** Backdoor insertion, long-term persistence
- **Capability:** High
- **Access:** Via compromised dependencies, base images

## Document Structure

```
Threat_Model/
├── README.md (this file)
├── models/
│   ├── vpc-threat-model.md          # Detailed VPC analysis
│   ├── cicd-threat-model.md         # CI/CD pipeline analysis
│   ├── iam-threat-model.md          # IAM and access control
│   └── template.md                  # Template for future models
├── diagrams/
│   ├── data-flow-diagram.md         # System data flows
│   ├── attack-trees.md              # Attack scenario trees
│   └── trust-boundaries.md          # Trust boundary documentation
└── docs/
    ├── stride-reference.md          # STRIDE methodology guide
    ├── risk-matrix.md               # Risk assessment criteria
    └── findings-summary.md          # Executive summary
```

## Quick Start

1. **Review the architecture**: Start with [data-flow-diagram.md](diagrams/data-flow-diagram.md)
2. **Understand threats**: Read [vpc-threat-model.md](models/vpc-threat-model.md)
3. **Check controls**: Review mitigations in each threat model
4. **Assess risks**: See [findings-summary.md](docs/findings-summary.md)

## Methodology

We use **STRIDE** to systematically identify threats:

- **S**poofing - Pretending to be someone else
- **T**ampering - Modifying data or code
- **R**epudiation - Denying actions
- **I**nformation Disclosure - Exposing sensitive data
- **D**enial of Service - Making system unavailable
- **E**levation of Privilege - Gaining unauthorized access

Each component is analyzed through this lens, threats are documented, and mitigations are mapped.

## Risk Rating

| Rating | Likelihood | Impact | Action Required |
|--------|-----------|---------|-----------------|
| **CRITICAL** | High | Critical | Immediate mitigation |
| **HIGH** | High | High OR Medium | Critical | Mitigate within 30 days |
| **MEDIUM** | Medium | Medium | Mitigate within 90 days |
| **LOW** | Low | Low/Medium | Accept or mitigate opportunistically |

## Validation & Maintenance

- **Initial Review:** February 14, 2026
- **Review Frequency:** Quarterly or when architecture changes
- **Owner:** DevSecOps Team
- **Last Updated:** February 14, 2026

## Key Findings Summary

| Finding | Severity | Status |
|---------|----------|--------|
| IMDSv1 enabled on EC2 | HIGH | ✅ MITIGATED (IMDSv2 enforced) |
| Public S3 buckets | CRITICAL | ✅ MITIGATED (Block public access) |
| Overly permissive SGs | MEDIUM | ✅ MITIGATED (Principle of least privilege) |
| No WAF on ALB | HIGH | ⚠️ RECOMMENDED |
| Secrets in environment variables | MEDIUM | ✅ MITIGATED (Secrets Manager) |
| No container scanning | MEDIUM | ⚠️ RECOMMENDED |

## References

- [STRIDE Threat Modeling](https://docs.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)
- [OWASP Threat Modeling](https://owasp.org/www-community/Threat_Modeling)
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Document Classification:** Internal
**Version:** 1.0
**Status:** Active
