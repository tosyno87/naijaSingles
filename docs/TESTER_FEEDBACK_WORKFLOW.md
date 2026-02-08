# Tester Feedback Workflow - SDLC Best Practices

## Overview

This guide outlines the standard SDLC workflow for handling tester feedback from TestFlight or other testing channels.

## Step-by-Step Workflow

### Step 1: Collect and Triage Feedback ✅

**What to do:**
1. **Collect all feedback** from:
   - TestFlight feedback
   - In-app feedback
   - Direct communication
   - Bug reports

2. **Categorize by severity:**
   - **P0 (Critical)**: App crashes, data loss, security issues
   - **P1 (High)**: Major feature broken, blocking user flow
   - **P2 (Medium)**: Minor bugs, UI issues
   - **P3 (Low)**: Nice-to-have improvements, polish

3. **Prioritize:**
   - Critical issues first
   - High-impact issues next
   - Group similar issues together

### Step 2: Create Jira Issues ✅

**Before writing any code, create Jira issues:**

1. **Go to Jira** and create issues for each feedback item
2. **Follow naming conventions:**
   - **Bugs**: `BUG-XXX: [Component] - [Issue Description]`
   - **Stories**: `STORY-XXX: [Feature Area] - [User Request]`
   - **Tasks**: `TASK-XXX: [Area] - [Technical Action]`

3. **Example issues:**
   - `BUG-15: Communities - App crashes when tapping Events card`
   - `BUG-16: Profile - Profile images not loading`
   - `STORY-42: UI/UX - Improve Communities welcome screen`

4. **Add details:**
   - Screenshots (if available)
   - Steps to reproduce
   - Expected vs. actual behavior
   - Device/OS information
   - Priority level

### Step 3: Switch to Main Branch ✅

**Yes, always start from main:**

```bash
# 1. Ensure you're on main and it's up to date
git checkout main
git pull origin main

# 2. Verify you're on the latest
git status
```

**Why start from main?**
- ✅ Ensures you're working with the latest stable code
- ✅ Avoids conflicts with other features
- ✅ Clean starting point
- ✅ Follows Git Flow best practices

### Step 4: Create Feature Branch ✅

**Create branch from main using Jira issue key:**

```bash
# Format: [type]/AFRO-[issue-number]-[short-description]
git checkout -b bug/AFRO-15-fix-communities-crash
# or
git checkout -b fix/AFRO-16-profile-image-loading
```

**Branch naming examples:**
- `bug/AFRO-15-fix-communities-crash`
- `fix/AFRO-16-profile-image-loading`
- `feature/AFRO-42-improve-communities-ui`

**Best Practice:**
- One issue = One branch (when possible)
- If multiple related issues, group them in one branch
- Use descriptive names

### Step 5: Implement Fix ✅

**Development process:**

1. **Understand the issue:**
   - Reproduce the bug locally
   - Understand root cause
   - Check related code

2. **Write the fix:**
   - Fix the issue
   - Follow coding standards
   - Add comments if needed

3. **Test locally:**
   - Test the fix
   - Test edge cases
   - Verify no regressions

4. **Write/update tests:**
   - Add tests for the fix
   - Update existing tests if needed
   - Ensure tests pass

### Step 6: Commit with Jira Issue Key ✅

**Always include Jira issue key in commit:**

```bash
# Format: AFRO-[issue-number]: [type]: [description]
git add .
git commit -m "AFRO-15: fix: resolve Communities screen crash on Events tap"
```

**Commit message types:**
- `fix`: Bug fix
- `feat`: New feature
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `docs`: Documentation

### Step 7: Push and Create PR ✅

**Push branch and create Pull Request:**

```bash
# Push branch
git push origin bug/AFRO-15-fix-communities-crash

# Create PR via GitHub CLI (or web UI)
gh pr create --title "[AFRO-15] fix: Resolve Communities Screen Crash" --body "Fixes issue reported by tester: App crashes when tapping Events card in Communities screen."
```

**PR Title Format:**
```
[AFRO-XXX] [Type]: [Description]
```

**PR Description should include:**
- Jira issue link
- Problem description
- Solution approach
- Testing done
- Screenshots (if UI change)

### Step 8: Code Review and Merge ✅

**Review process:**

1. **Automated checks run:**
   - Tests pass
   - Code quality checks
   - SonarQube analysis
   - Build validation

2. **Code review:**
   - Team reviews the PR
   - Address review comments
   - Update PR if needed

3. **Merge to main:**
   - Merge when approved
   - Delete feature branch (optional)

### Step 9: Deploy to TestFlight ✅

**After merge to main:**

1. **GitHub Actions automatically:**
   - Builds iOS app
   - Uploads to App Store Connect
   - Deploys to TestFlight

2. **Wait for build:**
   - Check GitHub Actions
   - Wait for build to complete (~15-20 minutes)
   - Verify upload successful

3. **Notify testers:**
   - Let testers know new build is available
   - Share build number
   - Ask them to test the fix

### Step 10: Verify Fix and Close Loop ✅

**Close the feedback loop:**

1. **Tester verification:**
   - Tester confirms fix works
   - Tester tests on their device
   - Collect confirmation

2. **Update Jira:**
   - Mark issue as "Resolved"
   - Add tester confirmation
   - Close issue

3. **Document:**
   - Update release notes
   - Document the fix
   - Share learnings with team

## Complete Workflow Diagram

```
Tester Feedback
    ↓
Create Jira Issue (AFRO-XXX)
    ↓
Switch to main branch
    ↓
Create feature branch (bug/AFRO-XXX-description)
    ↓
Implement fix
    ↓
Test locally
    ↓
Commit (AFRO-XXX: fix: description)
    ↓
Push and create PR
    ↓
Code review
    ↓
Merge to main
    ↓
GitHub Actions → Build → TestFlight
    ↓
Tester verifies fix
    ↓
Close Jira issue
```

## Best Practices

### ✅ Do's

1. **Always create Jira issue first**
   - Before writing code
   - Track all feedback
   - Link to PRs

2. **Start from main branch**
   - Latest stable code
   - Avoid conflicts
   - Clean starting point

3. **One issue per branch** (when possible)
   - Easier to review
   - Easier to revert
   - Clear history

4. **Include Jira key in commits**
   - `AFRO-15: fix: description`
   - Links commits to issues
   - Better traceability

5. **Test before PR**
   - Reproduce issue
   - Test fix
   - Test edge cases

6. **Update Jira after merge**
   - Mark as resolved
   - Add build number
   - Close when verified

### ❌ Don'ts

1. **Don't fix without Jira issue**
   - Always create issue first
   - Track all work
   - Maintain audit trail

2. **Don't work directly on main**
   - Always use feature branches
   - Protect main branch
   - Enable code review

3. **Don't skip testing**
   - Always test locally
   - Verify fix works
   - Check for regressions

4. **Don't forget to close loop**
   - Verify with tester
   - Update Jira
   - Document fix

## Priority-Based Workflow

### P0 (Critical) - Immediate Action

**Workflow:**
1. Create Jira issue immediately
2. Create hotfix branch from main
3. Fix immediately
4. Fast-track PR review
5. Deploy to TestFlight ASAP
6. Notify testers immediately

**Timeline:** Same day or within 24 hours

### P1 (High) - Next Sprint

**Workflow:**
1. Create Jira issue
2. Add to sprint backlog
3. Create feature branch
4. Fix in current/next sprint
5. Normal PR process
6. Deploy in next release

**Timeline:** Within 1-2 weeks

### P2 (Medium) - Upcoming Sprint

**Workflow:**
1. Create Jira issue
2. Add to backlog
3. Prioritize in sprint planning
4. Fix in upcoming sprint
5. Normal PR process

**Timeline:** Within 2-4 weeks

### P3 (Low) - Backlog

**Workflow:**
1. Create Jira issue
2. Add to backlog
3. Review in sprint planning
4. Fix when time permits

**Timeline:** When resources available

## Example: Handling Your First Issue

### Scenario: "App crashes when tapping Events card in Communities"

**Step 1: Create Jira Issue**
- Issue: `BUG-15: Communities - App crashes when tapping Events card`
- Priority: P1 (High)
- Description: Include screenshot and steps to reproduce

**Step 2: Switch to Main**
```bash
git checkout main
git pull origin main
```

**Step 3: Create Branch**
```bash
git checkout -b bug/AFRO-15-fix-communities-crash
```

**Step 4: Fix the Issue**
- Investigate crash
- Fix the bug
- Test locally
- Add tests if needed

**Step 5: Commit**
```bash
git add .
git commit -m "AFRO-15: fix: resolve Communities screen crash on Events tap"
```

**Step 6: Push and PR**
```bash
git push origin bug/AFRO-15-fix-communities-crash
# Create PR via GitHub
```

**Step 7: After Merge**
- GitHub Actions builds and deploys
- New build available in TestFlight
- Tester verifies fix
- Close Jira issue

## Tools and Resources

### Jira
- Create issues: https://your-jira-instance.atlassian.net
- Project key: `AFRO`
- Link PRs to issues

### GitHub
- Create branches
- Create PRs
- Review code
- Track deployments

### TestFlight
- Distribute builds
- Collect feedback
- Track tester activity

### SonarCloud
- Code quality checks
- Coverage tracking
- Security analysis

## Summary

**Standard Workflow:**
1. ✅ Collect feedback → Create Jira issue
2. ✅ Switch to main branch
3. ✅ Create feature branch (bug/AFRO-XXX-description)
4. ✅ Implement fix
5. ✅ Commit with Jira key (AFRO-XXX: fix: description)
6. ✅ Push and create PR
7. ✅ Code review and merge
8. ✅ Auto-deploy to TestFlight
9. ✅ Tester verifies
10. ✅ Close Jira issue

**Key Principles:**
- Always start from main
- Always create Jira issue first
- One issue per branch (when possible)
- Include Jira key in commits
- Test before PR
- Close the feedback loop

---

**Next Steps for Your First Issue:**
1. Create Jira issue for the feedback
2. Switch to main: `git checkout main && git pull`
3. Create branch: `git checkout -b bug/AFRO-XXX-description`
4. Start fixing!

