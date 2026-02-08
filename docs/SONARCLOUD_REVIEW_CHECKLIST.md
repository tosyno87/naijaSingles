# SonarCloud Issue Review - Quick Checklist

Use this checklist when reviewing SonarCloud issues.

## 🔴 Critical/Blocker Issues

- [ ] **Security Vulnerability?** → ✅ Fix immediately (create security ticket)
- [ ] **Will it crash?** → ✅ Fix immediately
- [ ] **Data loss risk?** → ✅ Fix immediately
- [ ] **User data exposure?** → ✅ Fix immediately

**Action:** Fix before merging, create `AFRO-XXX` bug ticket if needed

## 🟠 Major Issues (Bugs)

- [ ] **Actual bug that causes incorrect behavior?** → ✅ Fix
- [ ] **Null pointer exception in production code?** → ✅ Fix
- [ ] **Missing error handling in critical path?** → ✅ Fix
- [ ] **Logic error?** → ✅ Fix
- [ ] **False positive?** → ❌ Suppress with comment

**Action:** Fix before merging or create `AFRO-XXX` bug ticket

## 🟡 Minor Issues (Code Smells)

### Cognitive Complexity
- [ ] Complexity > 20? → ✅ Refactor
- [ ] Complexity 15-20? → ⚠️ Consider refactoring
- [ ] Well-documented & tested? → ❌ Can defer
- [ ] Required by business logic? → ❌ Suppress with reason

**Action:** Fix if >20, else add to technical debt backlog

### Code Duplication
- [ ] Duplicated 5+ times? → ✅ Extract to constant/function
- [ ] String/number literals? → ✅ Extract to constant
- [ ] Duplicated logic? → ✅ Extract to function
- [ ] Test code only? → ❌ Usually OK
- [ ] Framework boilerplate? → ❌ Usually OK

**Action:** Extract if used 3+ times, else defer

### Other Code Smells
- [ ] Method > 100 lines? → ✅ Split method
- [ ] Missing error handling in async? → ✅ Add try/catch
- [ ] Magic numbers without context? → ✅ Extract to constant
- [ ] Unclear naming? → ✅ Rename for clarity

**Action:** Fix if impacts maintainability, else defer

## 🔵 Info Issues (Best Practices)

- [ ] **Blocks quality gate?** → ✅ Fix
- [ ] **Easy fix (< 5 min)?** → ✅ Fix
- [ ] **In code I'm modifying?** → ✅ Fix while there
- [ ] **Low priority?** → ⚠️ Add to backlog

**Action:** Fix easy wins, backlog the rest

## Decision Tree

```
Is it a Security issue?
├─ YES → Fix immediately ✅
└─ NO → Continue

Is it a Bug?
├─ YES → Will it cause problems?
│   ├─ YES → Fix ✅
│   └─ NO → Suppress with reason ❌
└─ NO → Continue

Is it in Critical Path? (Auth, Payment, Data)
├─ YES → Fix ✅
└─ NO → Continue

Is it a Code Smell?
├─ Complexity > 20? → Fix ✅
├─ Used 5+ times? → Fix ✅
├─ Easy fix (< 15 min)? → Fix ✅
└─ ELSE → Defer to backlog ⚠️

Is it Low Priority?
└─ Add to technical debt backlog ⚠️
```

## Quick Actions

### Fix Now ✅
- Security vulnerabilities
- Critical bugs
- Issues blocking quality gate
- Easy fixes in code you're modifying

### Fix This Sprint ⚠️
- Major bugs
- High-impact code smells
- Issues in critical paths
- Coverage gaps in critical code

### Technical Debt Backlog 📋
- Minor code smells
- Low-priority improvements
- Legacy code issues
- Non-critical refactoring

### Suppress/Ignore ❌
- False positives
- Intentional patterns
- Framework requirements
- Generated code (if excluded)

## Suppression Template

```dart
// Suppressed: [Reason]
// [Brief explanation why this is acceptable]
// Example: Complexity required for state machine with 10+ transitions
```

## Jira Ticket Template

When creating tickets from SonarCloud issues:

**Title:** `[Component] - [Issue Description]`
**Type:** Bug or Technical Debt
**Priority:** Based on severity
**Description:**
```
SonarCloud Issue: [Link to issue]
Severity: [Critical/Major/Minor/Info]
File: [path]
Line: [number]

[Issue description]

[Why it needs to be fixed]
```

## Review Time Estimates

- **Critical/Major:** 1-4 hours each
- **Minor Code Smells:** 15-60 min each
- **Info/Suggestions:** 5-15 min each

**Batch similar issues** to save time (e.g., fix all duplication in one file together).

