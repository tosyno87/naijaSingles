# CI Failure Investigation — 4 Failing Checks

## gh CLI investigation (run 22840454208)

```bash
gh run list --limit 10 --branch feat/match-quality-operations-infra
gh run view 22840454208
gh run view 22840454208 --log-failed
```

**Result:** Only **Build Validation (android)** failed. Code Quality, Unit Tests, Security, and SonarQube passed.

**Failed step:** `Build Android APK` (`flutter build apk --release`).

**Root causes from log:**

1. **Crashlytics vs Google Services**
   - `The Crashlytics Gradle plugin 3 requires Google-Services 4.4.1 and above.`
   - Project had `com.google.gms.google-services` **4.3.15** in `android/settings.gradle`.

2. **Android compileSdk**
   - Project used `compileSdk = 35`; several plugins require **36** (flutter_plugin_android_lifecycle, geolocator_android, google_maps_flutter_android, etc.).

**Fix applied:**

- `android/settings.gradle`: `google-services` version **4.3.15 → 4.4.2**.
- `android/app/build.gradle`: `compileSdk = 35` → **36**.

---

## Summary of Failing Checks

| Check | Trigger | Likely cause |
|-------|--------|----------------|
| **CI - Quality Gates & SonarQube / Build Validation (android)** | `pull_request` & `push` | Upstream job failure (code-quality, tests, or security) **or** `flutter build apk --release` failure. |
| **SonarCloud Code Analysis** | PR / main / develop | **Quality Gate failed** — SonarCloud’s gate (coverage, bugs, vulnerabilities, code smells) not met. |
| **Staging Deployment / Test and Build Staging** | `push` to **develop** only | Runs only on push to `develop` (e.g. after merge). Fails if secrets missing or build/test/analyzer fails. |

---

## 1. Build Validation (android)

**What it does:** Runs after `code-quality`, `security-analysis`, and `unit-tests-coverage`. Runs `flutter build apk --release`.

**Why it can fail:**

- **Dependency failure:** If any of the three jobs above fail or are skipped, the build job can show as failed (e.g. “Failing after 5m” if an upstream job failed).
- **Build failure:** `flutter build apk --release` fails (e.g. Gradle, signing, or compile error).

**What to do:**

1. Open the **Code Quality Analysis** and **Unit Tests with Coverage** logs for the same run:
   - GitHub PR → **Checks** → **CI - Quality Gates & SonarQube** → open the run → open **Code Quality Analysis** and **Unit Tests with Coverage**.
2. If **Code Quality** failed: check which step failed:
   - Duplicate-suffix script
   - `npm run test:rules`
   - Golden tests (skipped tests)
   - `flutter analyze` (issues > 0)
   - `dart format --set-exit-if-changed`
3. If **Build Validation** ran and failed on its own: open **Build Validation (android)** and read the last lines of the log (Gradle/Flutter error).

**This PR (match quality operations infra):** Only Firestore, Cloud Functions (TypeScript), docs, and reports were changed. No Dart/Flutter `lib/` or `test/` changes, so code-quality and build are unlikely to be broken by this PR unless something is flaky or env-specific.

---

## 2. SonarCloud Code Analysis — “Quality Gate failed”

**What it does:** Runs on PRs and on `main`/`develop`. Builds the app, runs tests with coverage, runs the SonarCloud scan, then checks the **Quality Gate** (configured in SonarCloud UI).

**Why it fails:** The Quality Gate in SonarCloud (e.g. coverage, duplicated lines, maintainability, reliability, security, code smells) is not satisfied. Common causes:

- **Coverage** on new code or overall below the gate threshold.
- **New issues** (bugs, vulnerabilities, code smells) in the changed or new code.
- **Reference branch:** Gate is evaluated against `main` (`sonar.newCode.referenceBranch=main`). New code vs `main` may introduce or expose issues.

**What to do:**

1. Open SonarCloud and the project **tosyno87/naijaSingles**:
   - [SonarCloud dashboard](https://sonarcloud.io) → select the project.
2. Check the **Quality Gate** result and the **“Why did this fail?”** (or equivalent) section.
3. Fix or relax the gate:
   - **Fix:** Address reported issues (coverage, bugs, code smells, etc.) in the codebase or in this PR.
   - **Relax (temporary):** In SonarCloud → **Quality Gates** → edit the gate used by this project (e.g. lower coverage or disable a condition) — only if acceptable for your process.

**This PR:** No Dart `lib/` or `test/` changes; SonarCloud is configured with `sonar.sources=lib` and `sonar.tests=test,integration_test`, so the failure is likely **pre-existing** or from other PRs targeting the same branch, unless SonarCloud is also analyzing other paths.

---

## 3. Staging Deployment / Test and Build Staging (push)

**What it does:** Defined in `staging.yml`. Runs **only on `push` to `develop`** (not on every PR). Steps: create `.env`, `flutter pub get`, `flutter analyze`, `flutter test --coverage`, `flutter build web`, then (if auth succeeds) deploy to Firebase Hosting.

**Why it can fail:**

- **Secrets:** `FIREBASE_TOKEN_STAGING` or `GOOGLE_SERVICE_ACCOUNT_STAGING` missing or invalid → **Authenticate to Google Cloud** fails (or deploy step fails).
- **Analyzer / tests / build:** `flutter analyze`, `flutter test`, or `flutter build web` fails on the tip of `develop`.

**What to do:**

1. Confirm the run is for a **push to `develop`** (e.g. after a merge), not for the feature branch.
2. Open the **Test and Build Staging** job log and find the first failed step.
3. If **Authenticate to Google Cloud** or **Deploy to Staging** failed: add or fix `FIREBASE_TOKEN_STAGING` and `GOOGLE_SERVICE_ACCOUNT_STAGING` in the repo **Settings → Secrets and variables → Actions**.
4. If **Run Flutter analyzer**, **Run tests**, or **Build Staging Web** failed: fix the reported errors on `develop`.

---

## Quick checklist

- [ ] Open the **CI - Quality Gates & SonarQube** run for this PR and confirm which job failed first: **Code Quality Analysis**, **Unit Tests with Coverage**, or **Build Validation**.
- [ ] In the failed job, identify the **exact step** that failed and the error message.
- [ ] In SonarCloud, open the project and the latest analysis; note which Quality Gate condition failed.
- [ ] For **Staging**, confirm the run is for `push` to `develop`; then check the first failing step and secrets.

---

## References

- **CI workflow:** `.github/workflows/ci.yml`
- **Staging workflow:** `.github/workflows/staging.yml`
- **Sonar config:** `sonar-project.properties`
- **Quality gate (SonarCloud):** Configured in [SonarCloud → Project → Quality Gate](https://sonarcloud.io).
