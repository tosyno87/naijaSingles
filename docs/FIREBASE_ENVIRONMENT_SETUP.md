# Firebase Environment Setup - Best Practices & Recommendations

## Current State Analysis

### ✅ What You Have
- **1 Firebase Project**: `naijasingles-74a75` (currently used for everything)
- **Flutter App**: Configured for dev/staging/production environments
- **CI/CD**: GitHub Actions workflows for staging and production
- **Cloud Functions**: Deployed and working

### ⚠️ Current Issue
All environments (dev, staging, production) point to the **same Firebase project**. This is a **security risk** and not a best practice.

---

## Recommended Firebase Project Structure

### Option 1: Three Separate Projects (Recommended for Production Apps)

```
┌─────────────────────────────────────────────────────────┐
│ Development Project                                     │
│ • Project ID: naijasingles-dev (or naijasingles-74a75) │
│ • Purpose: Local development, testing, experimentation │
│ • Security: Relaxed rules, test data allowed           │
│ • Cost: Free tier is usually enough                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Staging Project                                         │
│ • Project ID: naijasingles-staging                     │
│ • Purpose: Pre-production testing, QA, TestFlight      │
│ • Security: Production-like rules, real user testing   │
│ • Cost: Pay as you go (similar to production)          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Production Project                                      │
│ • Project ID: naijasingles-prod                        │
│ • Purpose: Live users, real data, App Store release    │
│ • Security: Strict rules, monitoring, backups          │
│ • Cost: Pay as you go                                   │
└─────────────────────────────────────────────────────────┘
```

**Advantages:**
- ✅ Complete isolation between environments
- ✅ No risk of production data corruption
- ✅ Independent scaling and quotas
- ✅ Separate billing and cost tracking
- ✅ Can test migrations safely in staging
- ✅ Production stays clean (no test data)

**Cost:** Free tier for dev, pay-as-you-go for staging/prod (similar cost to having one project)

---

### Option 2: Two Projects (Pragmatic for Small Teams)

If you're a small team or early stage:

```
┌─────────────────────────────────────────────────────────┐
│ Development + Staging (Combined)                        │
│ • Project ID: naijasingles-dev                         │
│ • Purpose: Development, testing, TestFlight builds     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ Production                                              │
│ • Project ID: naijasingles-prod                        │
│ • Purpose: Live users only                             │
└─────────────────────────────────────────────────────────┘
```

**Advantages:**
- ✅ Simpler setup
- ✅ Lower management overhead
- ✅ Still isolates production
- ✅ Good enough for early stages

---

## Implementation Steps

### Step 1: Create New Firebase Projects

```bash
# Create staging project (if using Option 1)
firebase projects:create naijasingles-staging --display-name "NaijaSingles Staging"

# Create production project (if using Option 1 or 2)
firebase projects:create naijasingles-prod --display-name "NaijaSingles Production"

# Or keep current as dev, create only production (if using Option 2)
firebase projects:create naijasingles-prod --display-name "NaijaSingles Production"
```

### Step 2: Update .firebaserc

```json
{
  "projects": {
    "default": "naijasingles-74a75",  // Keep current as dev
    "development": "naijasingles-74a75",
    "staging": "naijasingles-staging",
    "production": "naijasingles-prod"
  }
}
```

### Step 3: Update Environment Config Files

**lib/env/development.dart:**
```dart
static const String firebaseProjectId = 'naijasingles-74a75'; // Keep as is
```

**lib/env/staging.dart:**
```dart
static const String firebaseProjectId = 'naijasingles-staging'; // Update
```

**lib/env/production.dart:**
```dart
static const String firebaseProjectId = 'naijasingles-prod'; // Update
```

### Step 4: Set Up Each Project

For each new project, you'll need to:

1. **Enable required services:**
   - Authentication
   - Firestore Database
   - Cloud Storage
   - Cloud Functions
   - Cloud Messaging (FCM)

2. **Copy Firestore rules:**
   ```bash
   # Copy rules to staging
   firebase deploy --only firestore:rules --project naijasingles-staging
   
   # Copy rules to production
   firebase deploy --only firestore:rules --project naijasingles-prod
   ```

3. **Copy Storage rules:**
   ```bash
   firebase deploy --only storage --project naijasingles-staging
   firebase deploy --only storage --project naijasingles-prod
   ```

4. **Deploy Cloud Functions:**
   ```bash
   # Deploy to staging
   firebase deploy --only functions --project naijasingles-staging
   
   # Deploy to production (after testing)
   firebase deploy --only functions --project naijasingles-prod
   ```

5. **Set up Firebase App configuration:**
   - Download `google-services.json` (Android) for each project
   - Download `GoogleService-Info.plist` (iOS) for each project
   - Update Flutter Firebase configuration

### Step 5: Update CI/CD Workflows

**`.github/workflows/staging.yml`:**
```yaml
env:
  FIREBASE_PROJECT_ID: naijasingles-staging  # Update this
```

**`.github/workflows/production.yml`:**
```yaml
env:
  FIREBASE_PROJECT_ID: naijasingles-prod  # Update this
```

---

## Security Best Practices

### 1. Firestore Security Rules

**Development:**
- More permissive (for testing)
- Allow test data creation
- Enable debugging

**Staging:**
- Production-like rules
- Real user data patterns
- Enable analytics

**Production:**
- Strictest rules
- No test data allowed
- Full monitoring

### 2. Admin Secrets for Cloud Functions

Set different secrets per environment:

```bash
# Development
firebase functions:config:set admin.secret="dev-secret-token" --project naijasingles-74a75

# Staging
firebase functions:config:set admin.secret="staging-secret-token" --project naijasingles-staging

# Production
firebase functions:config:set admin.secret="production-secure-random-token" --project naijasingles-prod
```

Generate secure tokens:
```bash
openssl rand -hex 32  # Use this output as secret
```

### 3. Environment Variables

Use GitHub Secrets for CI/CD:
- `FIREBASE_TOKEN_STAGING`
- `FIREBASE_TOKEN_PRODUCTION`
- `ADMIN_SECRET_STAGING`
- `ADMIN_SECRET_PRODUCTION`

---

## Migration Strategy

### Phase 1: Setup (Week 1)
1. Create new Firebase projects
2. Update `.firebaserc`
3. Update environment config files
4. Set up basic services in new projects

### Phase 2: Deploy (Week 1-2)
1. Deploy Cloud Functions to staging
2. Deploy Firestore/Storage rules
3. Test staging environment thoroughly
4. Deploy to production

### Phase 3: Migrate Data (If Needed)
1. Export current data (if you want to seed staging)
2. Import to staging project
3. Test thoroughly
4. For production: Start fresh (recommended for new apps)

### Phase 4: Clean Up
1. Update all documentation
2. Update CI/CD workflows
3. Train team on new environment structure

---

## Cost Considerations

### Current Setup (1 Project)
- **Free Tier**: 50K reads/day, 20K writes/day
- **Cost**: Pay-as-you-go after free tier

### Recommended Setup (3 Projects)
- **Dev Project**: Usually stays in free tier
- **Staging Project**: Low usage, minimal cost
- **Production Project**: Main cost center

**Total Cost**: Similar or slightly higher (due to separate projects), but:
- Better isolation
- Better security
- Better for scaling
- Industry standard

---

## Quick Start (If Starting Fresh)

If you're early stage and want to implement this now:

```bash
# 1. Keep current project as dev
# Current: naijasingles-74a75 (development)

# 2. Create production project
firebase projects:create naijasingles-prod

# 3. Update .firebaserc
# 4. Update environment configs
# 5. Deploy to production when ready
```

---

## Recommended Next Steps (Priority Order)

1. ✅ **Keep current setup for now** (if you're still in development)
2. 🔄 **Create production project** (when preparing for App Store)
3. 🔄 **Set up staging project** (when you have beta testers)
4. 🔒 **Configure admin secrets** for each environment
5. 📝 **Update CI/CD** to use correct projects
6. 🧪 **Test thoroughly** in staging before production

---

## Decision Matrix

**Choose Option 1 (3 Projects) if:**
- ✅ You have or will have paying customers
- ✅ You want maximum isolation
- ✅ You have a team working on the app
- ✅ You're preparing for App Store release
- ✅ Budget allows for multiple projects

**Choose Option 2 (2 Projects) if:**
- ✅ You're a solo developer or small team
- ✅ You're still in early development
- ✅ You want simpler management
- ✅ You want to save on setup time
- ✅ Production isolation is priority

**Keep Current (1 Project) only if:**
- ✅ You're in very early prototype stage
- ✅ You have no users yet
- ✅ You're testing the concept
- ⚠️ **Plan to migrate soon** as you grow

---

## Additional Resources

- [Firebase Project Management](https://firebase.google.com/docs/projects/overview)
- [Environment Configuration Best Practices](https://firebase.google.com/docs/functions/config-env)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [CI/CD with Firebase](https://firebase.google.com/docs/hosting/github-integration)
