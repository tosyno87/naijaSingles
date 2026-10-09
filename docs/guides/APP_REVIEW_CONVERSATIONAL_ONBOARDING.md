# App Review notes — conversational onboarding

Paste the **Reviewer notes** section into App Store Connect when you resubmit.
Do not pitch this as a world-first AI dating app. Pitch the product Apple
will actually use: Houston diaspora community first, profile drafted from the
user's own words, Connect through events — not a global swipe pile.

## Reviewer notes (copy/paste)

Afropeep is a Houston diaspora community app. After sign-in, onboarding lets
the reviewer talk or type about themselves. We draft a profile from those
words; the reviewer must confirm name, gender, and date of birth (18+), then
add photos and location. Recordings are not stored.

If drafting is unavailable, tap **Fill it in myself** for the standard form.

Demo account: use the TestFlight / App Review account already provided. If a
review UID is listed in `ONBOARDING_AI_REVIEW_UIDS`, the draft is a fixture so
review does not depend on a live model call.

After onboarding, the home experience is communities and events in Houston,
not a generic swipe deck. Please start from Discover / events.

## Houston home (Discover)

The first tab after onboarding is **Discover**, not Connect. Screenshots
must open on this Houston home: headline **New in Houston? Meet your
people.**, **This weekend** event rows, then Connect as a secondary module.

### Event supply (operators, not Apple)

The app does not seed events. Staging/review Firebase must already have
at least two published Houston events dated in the next 7 days.

```bash
cd functions
npx ts-node src/scripts/seedHoustonReviewEvents.ts --project naijasingles-staging
```

The script is idempotent (stable doc ids `houston-review-weekend-afrobeats`
and `houston-review-weekend-brunch`). It **refuses production** project ids
(`naijasingles-74a75`, `naijasingles-prod2`, `afropeep-prod-74a75`) unless
you pass `--i-am-sure`.

Reviewer account: `living_in` Houston, or empty so the client still prefers
Houston in the event haystack.

## Screenshots to capture (in this order)

1. Conversational onboarding — "Tell us who you are" consent, not swipe cards.
2. Talk-or-type prompts (heritage / Houston / what they are looking for).
3. Draft review with name, gender, and birthday confirmation.
4. Discover / events hub (community-first home).
5. A Houston event or community group.

Do **not** lead with Connect swipe.

## Operator setup (not for Apple)

```bash
firebase functions:secrets:set OPENAI_API_KEY
# Optional App Review fixture UIDs (comma-separated):
firebase functions:config:set is not used; set env ONBOARDING_AI_REVIEW_UIDS
# Daily cap (cents), default 1500:
# ONBOARDING_AI_DAILY_CAP_CENTS=1500
```

Deploy `extractOnboardingProfile` with the other Cloud Functions.
The spend kill switch lives at `runtimeConfig/onboardingAi` (Admin SDK).
Rate-limit stamps live at `onboardingExtractions/{uid}` (clients cannot read).
App Check is on by default (`ONBOARDING_AI_ENFORCE_APPCHECK`, same pattern as
account deletion). Set `false` only for local/dev.
