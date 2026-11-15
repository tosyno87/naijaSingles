# TestFlight Houston ops checklist

Run this **before every TestFlight cut** that demos Houston-first Discover + conversational onboarding. Owner: whoever cuts the build.

**Active TestFlight Firebase project:** confirm against the in-app env badge.
As of the Houston beta cut, the staging flavor points at **`naijasingles-74a75`**
(not the empty `naijasingles-staging` alias). Use that id for deploy/seed unless
the badge says otherwise.

`OPENAI_API_KEY` must be a **real** OpenAI key in Secret Manager before live
drafting works. A placeholder allows deploy + App Review fixture UIDs; other
users fall back to “Fill it in myself”.

```bash
printf '%s' 'sk-...' | gcloud secrets versions add OPENAI_API_KEY \
  --project=naijasingles-74a75 --data-file=-
# Then redeploy extractOnboardingProfile so the new version is mounted.
```

## 1. Cloud Functions

Preferred one-shot (defaults to `naijasingles-74a75`, passes `--i-am-sure` for seeds):

```bash
./scripts/testflight_houston_staging_ops.sh
# or explicitly:
./scripts/testflight_houston_staging_ops.sh naijasingles-74a75
```

Manual equivalent:

```bash
cd functions
firebase deploy --only functions --project naijasingles-74a75
```

Secrets / env:

```bash
firebase functions:secrets:set OPENAI_API_KEY --project naijasingles-74a75
# Optional App Review fixture UIDs (comma-separated Firebase Auth UIDs):
# Set ONBOARDING_AI_REVIEW_UIDS on the function runtime / params.
# App Check stays ON by default (ONBOARDING_AI_ENFORCE_APPCHECK).
```

## 2. Seed Discover content

```bash
cd functions
npx ts-node src/scripts/seedHoustonReviewEvents.ts --project naijasingles-74a75 --i-am-sure
npx ts-node src/scripts/seedHoustonReviewGroups.ts --project naijasingles-74a75 --i-am-sure
```

Expect: ≥2 published Houston weekend events and ≥2 public `unifiedGroups`.

Production project ids are refused unless `--i-am-sure` (the ops wrapper adds it).

## 3. Rules sanity

Confirm `onboardingExtractions/{userId}` remains Admin SDK only (`allow read, write: if false` in `firestore.rules`).

## 4. Cut build

Merge `feature/houston-first-home` (or follow-up fixes) to `develop`, then:

```bash
./scripts/deploy_testflight.sh --build-only              # ENV=production; note the IPA path
# Device-verify that exact build (startup: env=production project=naijasingles-74a75)
./scripts/deploy_testflight.sh --upload-only PATH.ipa    # path required; upload the SAME IPA — no rebuild
# Alternative: Xcode Organizer → open build/ios/archive/Runner.xcarchive → Distribute App
```

Do **not** re-run a full deploy after `--build-only` — that increments the build number and uploads a different, unverified IPA. Do **not** omit the IPA path on `--upload-only` (no auto-pick). Do **not** upload an IPA built without `--dart-define=ENV=production` — release startup rejects staging.

## 5. Screenshots (App Review order)

See [APP_REVIEW_CONVERSATIONAL_ONBOARDING.md](APP_REVIEW_CONVERSATIONAL_ONBOARDING.md) — onboarding → draft → Discover → event/group. Do **not** lead with Connect.
