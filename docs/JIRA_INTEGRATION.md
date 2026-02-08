# Jira Integration Guide

## Overview

GitHub is now connected to Atlassian/Jira. To track development work in Jira issues, you need to add **issue keys** to your branches, pull request titles, and commit messages.

## What are Issue Keys?

Issue keys are Jira ticket identifiers in the format: `PROJECT-123`

Examples:
- `AFRO-42` - Feature ticket #42 in the AFRO project
- `BUG-15` - Bug ticket #15
- `TECH-8` - Technical task #8

## How to Add Issue Keys

### 1. Branch Names

Include the issue key in your branch name:

**Format:** `feature/PROJECT-123-description` or `fix/PROJECT-123-description`

**Examples:**
```bash
# Good ✅
feature/AFRO-42-secure-storage-implementation
fix/BUG-15-profile-loading-issue
feature/TECH-8-sonarcloud-integration

# Bad ❌
feature/secure-storage-implementation  # Missing issue key
fix/profile-issue                      # Missing issue key
```

**Creating a branch with an issue key:**
```bash
git checkout -b feature/AFRO-42-secure-storage-implementation
```

### 2. Commit Messages

Include the issue key at the start of your commit message:

**Format:** `PROJECT-123: Description of changes`

**Examples:**
```bash
# Good ✅
git commit -m "AFRO-42: implement secure storage service"
git commit -m "BUG-15: fix profile loading issue"
git commit -m "TECH-8: add SonarCloud integration to CI"

# With detailed message
git commit -m "AFRO-42: implement secure storage service

- Add SecureStorageService singleton
- Integrate with authentication flow
- Add unit tests
- Update documentation"

# Bad ❌
git commit -m "implement secure storage service"  # Missing issue key
git commit -m "fix profile issue"                   # Missing issue key
```

### 3. Pull Request Titles

Include the issue key in your PR title:

**Format:** `[PROJECT-123] Description of changes`

**Examples:**
```markdown
# Good ✅
[AFRO-42] Implement secure storage service
[BUG-15] Fix profile loading issue
[TECH-8] Add SonarCloud integration to CI

# Bad ❌
Implement secure storage service  # Missing issue key
Fix profile issue                  # Missing issue key
```

### 4. Pull Request Descriptions

You can also reference issues in the PR description:

```markdown
## Description
Implements secure storage for sensitive data using flutter_secure_storage.

## Related Issues
- Closes AFRO-42
- Related to TECH-8

## Changes
- Added SecureStorageService
- Integrated with auth flow
- Added tests
```

## Automatic Linking

When you include issue keys in:
- **Branch names**: Jira will automatically link the branch to the issue
- **Commit messages**: Commits will appear in the Jira issue's "Development" panel
- **PR titles**: Pull requests will be linked to the Jira issue

## Best Practices

1. **Always include issue keys** when working on a Jira ticket
2. **Use consistent format**: `PROJECT-123` (uppercase, hyphen, number)
3. **One issue per branch**: Each branch should typically address one Jira issue
4. **Reference in PR**: Include the issue key in both title and description
5. **Link in commits**: Add issue key to every commit related to that issue

## Examples from This Project

### Current Branch (without issue key):
```bash
feature/secure-storage-implementation
```

### With Issue Key (if this was AFRO-42):
```bash
feature/AFRO-42-secure-storage-implementation
```

### Current Commit (without issue key):
```bash
git commit -m "security: fix SonarQube security hotspots in workflows"
```

### With Issue Key:
```bash
git commit -m "TECH-8: security: fix SonarQube security hotspots in workflows"
```

## Finding Your Issue Key

1. Open your Jira issue
2. Look at the top-left corner - the issue key is displayed (e.g., "AFRO-42")
3. Copy this key and use it in your branch/commit/PR

## Troubleshooting

**Issue not linking?**
- Check that the issue key format is correct: `PROJECT-123`
- Ensure the project key matches your Jira project
- Verify GitHub-Jira connection is active

**Multiple issues in one PR?**
- Use the primary issue key in the branch name and PR title
- Reference other issues in the PR description: "Related to BUG-15, TECH-8"

## Resources

- [Atlassian: Linking GitHub commits to Jira issues](https://support.atlassian.com/jira-software-cloud/docs/link-development-information-to-issues/)
- [GitHub: Jira integration](https://docs.github.com/en/enterprise-cloud@latest/admin/user-management/managing-users-in-your-enterprise/integrating-jira-with-your-enterprise)

---

**Note**: If you don't have a Jira issue for your work, you can:
1. Create one in Jira first
2. Use a generic format like `TECH-XXX` for technical improvements
3. Or proceed without an issue key (though linking won't work)

