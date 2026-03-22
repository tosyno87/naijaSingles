# Afropeep Firebase Migration Runbook (Phased Cutover)

## Scope (v1)
- Auth users
- Firestore profiles (`users/{uid}`)
- User media blobs/paths in Storage

## Branch + PR policy
- Work only on `codex/afropeep-firebase-migration`
- Merge via PR only
- CI must pass:
  - `scripts/verify_release_firebase_config.sh`
  - Flutter analyze/tests

## 1. Baseline new project (`afropeep-xxxx`)
1. Create Firebase project.
2. Enable products:
   - Authentication (Phone, Google, Apple as needed)
   - Firestore
   - Storage
   - FCM
   - App Check
3. Recreate production security:
   - Firestore rules/indexes
   - Storage rules
   - OAuth client IDs
   - APNs/FCM credentials
4. Configure Hosting:
   - `afropeep-xxxx.web.app`
   - custom domains `afropeep.com` and `www.afropeep.com`

## 2. App environment wiring
- `ENV=production` remains required for App Store production workflow.
- `ENV=next-production` is available for migration dress rehearsals.
- `lib/firebase_options_next_production.dart` requires explicit `--dart-define` values.
- One-time forced re-login is controlled by:
  - `--dart-define=FORCE_RELOGIN_AFTER_MIGRATION=true`
  - `--dart-define=AUTH_MIGRATION_CUTOVER_EPOCH=<integer>`

## 3. Auth migration
Export from legacy project:

```bash
scripts/migration/export_auth_users.sh naijasingles-74a75 ./tmp/auth-export.json
```

Import into new project:

```bash
scripts/migration/import_auth_users.sh afropeep-xxxx ./tmp/auth-export.json
```

Parity check:

```bash
scripts/migration/verify_auth_uid_parity.sh naijasingles-74a75 afropeep-xxxx
```

## 4. Profile + media migration
1. Migrate Firestore `users/{uid}` docs (UID must match Auth UID).
2. Migrate Storage media objects preserving path conventions.
3. Verify migrated profiles still satisfy onboarding routing:
   - complete profile -> main
   - incomplete profile -> onboarding
   - login unregistered phone -> NotRegistered

## 5. Cutover day flow
1. Freeze risky schema changes.
2. Run bulk migration.
3. Run delta sync in cutover window.
4. Ship release build to new project.
5. First launch after update forces re-login once.
6. Keep legacy project in read-safe standby during rollback window.

## 6. Rollback triggers
- Auth success rate drops below SLO.
- OTP failures spike.
- Crash-free users drop below threshold.
- Onboarding completion failures spike.

Rollback action:
1. Ship emergency build pointed to legacy project.
2. Keep both projects/secrets until exit criteria are met.

## 7. Verification matrix
- Fresh install/no session -> Welcome
- Complete session -> Main
- Incomplete session -> Onboarding
- Stale/invalid session -> Welcome
- Phone OTP:
  - valid code succeeds
  - invalid code fails
  - resend works
