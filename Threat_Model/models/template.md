# [Component/System Name] Threat Model

## 1. SYSTEM OVERVIEW

### What is Being Built?
[Brief description of the system/component being analyzed]

### What Data Does It Handle?
| Data Type | Sensitivity | Volume | Retention |
|-----------|-------------|--------|-----------|
| [Example: Customer PII] | CRITICAL | [High/Medium/Low] | [Duration] |

### Who Are the Users?
- **[User Type 1]:** [Description and access level]
- **[User Type 2]:** [Description and access level]

---

## 2. ARCHITECTURE DIAGRAM

```
[Insert ASCII diagram showing:
 - Components
 - Data flows
 - Trust boundaries
 - External dependencies]
```

### Trust Boundaries
- **TB1:** [Boundary description and significance]
- **TB2:** [Boundary description and significance]

---

## 3. THREAT ENUMERATION (STRIDE ANALYSIS)

### Component: [Component Name]

#### SPOOFING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-S1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

#### TAMPERING
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-T1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

#### REPUDIATION
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-R1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

#### INFORMATION DISCLOSURE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-I1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

#### DENIAL OF SERVICE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-D1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

#### ELEVATION OF PRIVILEGE
| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| [ID]-E1 | [Threat description] | [LOW/MEDIUM/HIGH] | [LOW/MEDIUM/HIGH/CRITICAL] | [LOW/MEDIUM/HIGH/CRITICAL] |

**Mitigations:**
- ✅ [Existing control]
- ⚠️ [Recommended control]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

## 4. RISK ASSESSMENT

### Critical Findings (Immediate Action Required)

| ID | Threat | Current Risk | Mitigation Priority |
|----|--------|--------------|---------------------|
| [ID] | [Threat summary] | [CRITICAL/HIGH] | [Action required] |

### High Findings (Mitigate within 30 days)

| ID | Threat | Current Risk | Recommended Mitigation |
|----|--------|--------------|------------------------|
| [ID] | [Threat summary] | [HIGH/MEDIUM] | [Recommended action] |

### Medium Findings (Mitigate within 90 days)

| ID | Threat | Current Risk | Recommended Mitigation |
|----|--------|--------------|------------------------|
| [ID] | [Threat summary] | [MEDIUM] | [Recommended action] |

---

## 5. MITIGATIONS

### Existing Controls (Implemented ✅)

#### [Control Category 1]
- ✅ [Specific control]
- ✅ [Specific control]

#### [Control Category 2]
- ✅ [Specific control]
- ✅ [Specific control]

---

### Recommended Additional Controls (⚠️)

#### Priority 1 (Immediate - within 7 days)
1. **[Control Name]**
   - [Description]
   - [Implementation steps]

#### Priority 2 (within 30 days)
2. **[Control Name]**
   - [Description]
   - [Implementation steps]

#### Priority 3 (within 90 days)
3. **[Control Name]**
   - [Description]
   - [Implementation steps]

---

### Residual Risks (Accepted)

| Risk | Justification | Owner |
|------|---------------|-------|
| [Risk description] | [Why accepting this risk] | [Team/Person] |

---

## 6. VALIDATION

### How Will Mitigations Be Tested?

#### Security Testing
- ✅ **[Test Type]:** [Frequency and description]
- ⚠️ **[Test Type]:** [Recommended frequency and description]

#### Compliance Validation
- ✅ **[Compliance Framework]:** [How validated]

#### Monitoring Effectiveness
- ✅ **[Monitoring Activity]:** [Frequency and owner]

---

### Review Schedule

| Activity | Frequency | Owner |
|----------|-----------|-------|
| Threat model review | [Quarterly/Monthly] | [Team/Person] |
| Architecture changes trigger review | Ad-hoc | [Team/Person] |
| Post-incident review | After incidents | [Team/Person] |

---

## 7. ATTACK SCENARIOS

### Scenario 1: [Attack Name]

**Attack Chain:**
```
1. [Attack step]
2. [Attack step]
3. [Attack step]
4. [Attack step]
5. [Final impact]
```

**Likelihood:** [LOW/MEDIUM/HIGH]
**Impact:** [LOW/MEDIUM/HIGH/CRITICAL]
**Current Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

**Mitigations:**
- ✅ [Existing mitigation]
- ⚠️ [Recommended mitigation]

**Residual Risk:** [LOW/MEDIUM/HIGH/CRITICAL]

---

## SUMMARY

### Security Posture: [POOR/FAIR/GOOD/EXCELLENT]

[Brief assessment of overall security posture]

### Key Gaps Identified:
1. [Gap 1]
2. [Gap 2]
3. [Gap 3]

### Recommended Next Steps:
1. **Week 1:** [Action]
2. **Week 2:** [Action]
3. **Week 3:** [Action]
4. **Week 4:** [Action]

---

**Document Classification:** [PUBLIC/INTERNAL/CONFIDENTIAL]
**Version:** 1.0
**Last Updated:** [Date]
**Next Review:** [Date + 90 days]
**Owner:** [Team/Person]
**Approver:** [Title]
