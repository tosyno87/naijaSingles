# Jira Issue Standards for AfroPeep

## Project Overview

**Project Key**: `AFRO`  
**Project Name**: AfroPeep  
**App Name**: AfroPeep (formerly NaijaSingles)  
**App Type**: Flutter-based dating and social networking app for Africans in the diaspora

## Quick Reference

### Issue Naming Formats
- **Story**: `[Feature Area] - [User Action/Outcome]`
- **Bug**: `[Component/Feature] - [Issue Description]`
- **Task**: `[Area] - [Technical Action]`
- **Epic**: `[Major Feature/Initiative]`

### Feature Areas for Tasks
CI/CD, Security, Performance, Infrastructure, Testing, DevOps, Auth, UI/UX, Architecture, Code Quality

### After Issue Creation
Once created, the issue will have a key like `AFRO-XXX`. Use that in:
- **Branch names**: `task/AFRO-XXX-short-description`
- **Commits**: `AFRO-XXX: type: description`
- **PR titles**: `[AFRO-XXX] Type: Description`

## Issue Types

### 1. Story (User Story)
**Purpose**: New features or enhancements from a user perspective

**Naming Convention**: `[Feature Area] - [User Action/Outcome]`

**Examples**:
- `Dating - Implement Super Like Feature`
- `Events - Add Event RSVP Reminder Notifications`
- `Profile - Allow Users to Add Multiple Profile Photos`
- `Chat - Enable Voice Message Support`
- `Communities - Create Community Discovery Page`

**Format**: `AFRO-XXX: [Feature Area] - [User Action/Outcome]`

### 2. Bug
**Purpose**: Defects or issues that need fixing

**Naming Convention**: `[Component/Feature] - [Issue Description]`

**Examples**:
- `Profile - Profile images not loading on Android`
- `Match - Swipe animation lagging on low-end devices`
- `Auth - Phone verification code not received`
- `Chat - Messages not syncing across devices`
- `Events - Event location not displaying on map`

**Format**: `AFRO-XXX: [Component/Feature] - [Issue Description]`

### 3. Task
**Purpose**: Technical work, refactoring, or non-user-facing improvements

**Naming Convention**: `[Area] - [Technical Action]`

**Examples**:
- `CI/CD - Add SonarCloud Integration`
- `Security - Implement Secure Storage Service`
- `Performance - Optimize Image Loading in Swipe Cards`
- `Infrastructure - Set Up Firebase Security Rules`
- `Testing - Add Integration Tests for Match Flow`

**Format**: `AFRO-XXX: [Area] - [Technical Action]`

### 4. Epic
**Purpose**: Large features or initiatives spanning multiple stories

**Naming Convention**: `[Major Feature/Initiative]`

**Examples**:
- `Video Calling Feature`
- `Community Hubs Redesign`
- `Profile Verification System`
- `Event Discovery Enhancement`
- `Safety & Moderation Improvements`

**Format**: `AFRO-XXX: [Major Feature/Initiative]`

### 5. Technical Debt
**Purpose**: Code quality improvements, refactoring, or technical improvements

**Naming Convention**: `[Component] - [Improvement Description]`

**Examples**:
- `Architecture - Refactor Auth BLoC to Use Repository Pattern`
- `Performance - Optimize Firestore Query Performance`
- `Code Quality - Remove Deprecated Provider Usage`
- `Testing - Increase Test Coverage for Match Service`

**Format**: `AFRO-XXX: [Component] - [Improvement Description]`

## Feature Area Categories

Use these consistent feature area prefixes:

### Core Features
- **Dating**: Swipe, match, like, super like functionality
- **Match**: Matching system, match notifications
- **Chat**: Messaging, conversations
- **Profile**: User profiles, profile editing, verification
- **Events**: Event discovery, RSVP, event management
- **Communities**: Community hubs, groups, community features

### Technical Areas
- **Auth**: Authentication, phone verification, login/logout
- **Security**: Security features, secure storage, encryption
- **Performance**: Performance optimizations
- **UI/UX**: User interface and experience improvements
- **Infrastructure**: Backend, Firebase, API changes
- **CI/CD**: Continuous integration and deployment
- **Testing**: Test coverage, test improvements
- **DevOps**: Deployment, monitoring, logging

### Platform-Specific
- **iOS**: iOS-specific issues or features
- **Android**: Android-specific issues or features
- **Web**: Web platform-specific issues or features

## Issue Description Template

### For Stories
```markdown
## User Story
As a [user type], I want [action] so that [benefit].

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
- Implementation approach
- Dependencies
- Testing requirements

## Related Issues
- Related to AFRO-XXX
- Blocks AFRO-YYY
```

### For Bugs
```markdown
## Description
[Clear description of the bug]

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- Platform: iOS/Android/Web
- App Version: X.X.X
- Device: [if applicable]

## Screenshots/Logs
[Attach if available]
```

### For Tasks
```markdown
## Description
[What needs to be done - clear, actionable description]

## Technical Approach
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Dependencies
- Requires AFRO-XXX (if any)
- Related to AFRO-YYY (if any)

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

## Priority Levels

1. **Critical**: App crashes, security vulnerabilities, data loss
2. **High**: Major feature broken, significant user impact
3. **Medium**: Minor feature issues, moderate user impact
4. **Low**: Nice-to-have improvements, minor enhancements

## Labels

Use consistent labels for categorization:

### Feature Labels
- `dating`
- `match`
- `chat`
- `profile`
- `events`
- `communities`
- `auth`
- `security`

### Technical Labels
- `flutter`
- `firebase`
- `bloc`
- `ui`
- `performance`
- `testing`
- `ci-cd`
- `devops`

### Platform Labels
- `ios`
- `android`
- `web`
- `cross-platform`

### Priority Labels
- `critical`
- `high-priority`
- `medium-priority`
- `low-priority`

## Branch Naming Convention

**Format**: `[type]/AFRO-[issue-number]-[short-description]`

**Examples**:
```bash
feature/AFRO-42-secure-storage-implementation
fix/AFRO-15-profile-loading-issue
task/AFRO-8-sonarcloud-integration
bug/AFRO-23-chat-sync-problem
```

## Commit Message Convention

**Format**: `AFRO-[issue-number]: [type] [description]`

**Types**: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`

**Examples**:
```bash
AFRO-42: feat: implement secure storage service
AFRO-15: fix: resolve profile loading issue on Android
AFRO-8: chore: add SonarCloud integration to CI
AFRO-23: fix: sync chat messages across devices
AFRO-50: refactor: optimize image loading in swipe cards
```

## Pull Request Title Convention

**Format**: `[AFRO-XXX] [Type]: [Description]`

**Examples**:
```markdown
[AFRO-42] feat: Implement secure storage service
[AFRO-15] fix: Resolve profile loading issue on Android
[AFRO-8] chore: Add SonarCloud integration to CI
[AFRO-23] fix: Sync chat messages across devices
```

## Pull Request Description Template

```markdown
## Description
[Brief description of changes]

## Related Issue
Closes AFRO-XXX
Related to AFRO-YYY

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Performance improvement
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed
- [ ] Tested on iOS
- [ ] Tested on Android

## Screenshots (if applicable)
[Attach screenshots]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally
```

## Sprint Planning

### Story Points
- **1 point**: Trivial task (< 2 hours)
- **2 points**: Small task (2-4 hours)
- **3 points**: Medium task (4-8 hours)
- **5 points**: Large task (1-2 days)
- **8 points**: Very large task (2-3 days)
- **13 points**: Epic-sized task (3+ days) - should be broken down

### Sprint Structure
- **Sprint Duration**: 2 weeks
- **Sprint Goal**: Clear objective for the sprint
- **Definition of Done**:
  - Code reviewed and approved
  - Tests written and passing
  - Documentation updated
  - Deployed to staging
  - QA verified (if applicable)

## Best Practices

1. **Always create a Jira issue** before starting work
2. **Link related issues** using "relates to", "blocks", "is blocked by"
3. **Update issue status** as work progresses
4. **Add comments** with progress updates and decisions
5. **Attach screenshots/logs** for bugs
6. **Close issues** only when fully complete and verified
7. **Use consistent naming** across all issues
8. **Tag appropriately** with labels
9. **Estimate accurately** using story points
10. **Keep descriptions clear** and actionable

## Examples by Feature Area

### Dating Feature Issues
- `AFRO-42: Dating - Implement Super Like Feature`
- `AFRO-43: Match - Add Match Notification Sound`
- `AFRO-44: Dating - Optimize Swipe Card Performance`

### Events Feature Issues
- `AFRO-50: Events - Add Event RSVP Reminder Notifications`
- `AFRO-51: Events - Implement Event Discovery Filters`
- `AFRO-52: Events - Add Event Sharing Functionality`

### Profile Feature Issues
- `AFRO-60: Profile - Allow Multiple Profile Photos`
- `AFRO-61: Profile - Add Profile Verification Badge`
- `AFRO-62: Profile - Implement Profile Completion Progress`

### Technical Issues
- `AFRO-100: Security - Implement Secure Storage Service`
- `AFRO-101: Performance - Optimize Firestore Query Performance`
- `AFRO-102: CI/CD - Add SonarCloud Integration`

---

**For integration with GitHub**: See `docs/JIRA_INTEGRATION.md` for details on linking Jira issues with branches, commits, and pull requests.

