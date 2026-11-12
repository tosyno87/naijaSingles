# Houston TestFlight smoke status

Updated during plan execution. Human follow-through for logged-in steps.

## Automated / agent checks

| Check | Status | Notes |
|-------|--------|-------|
| Unit tests (nav, Houston widgets, conversational onboarding) | Pass | `flutter test` focused suite |
| Cloud Function extract tests | Pass | text caps + onboarding gate |
| `extractOnboardingProfile` deployed | Pass | project `naijasingles-74a75` |
| Firestore rules deployed | Pass | includes `onboardingExtractions` deny |
| Houston weekend events seeded | Pass | `houston-review-weekend-*` |
| Houston public groups seeded | Pass | `houston-review-group-*` |
| PR to develop | Pass | https://github.com/tosyno87/naijaSingles/pull/225 |
| Pre-auth sim screenshot | Captured | `.playtest-houston/smoke/01_preauth.png` (auth gate) |
| `flutter build ipa` archive | Pass | `build/ios/archive/Runner.xcarchive` (1.0.1+16) |
| TestFlight IPA export / upload | Blocked | Needs Apple Distribution cert + App Store profile for `com.app.naijasingles` (team Adeola Babatunde lacks iOS App Store profile permission). Open archive in Xcode Organizer to distribute once certs are fixed. |

## Human smoke (post TestFlight / signed-in)

1. [ ] Fresh install → auth → conversational prompts → draft (18+) → photos/location → **Discover**
2. [ ] Discover: Houston hero + ≥2 weekend rows + Explore groups non-empty
3. [ ] Soft Connect CTA → Connect deck
4. [ ] AI unavailable / review UID → Fill it in myself → Discover
5. [ ] Messages still opens existing match chat
6. [ ] App Review screenshots in order from `APP_REVIEW_CONVERSATIONAL_ONBOARDING.md`

## Operator leftovers

- [ ] Replace placeholder `OPENAI_API_KEY` with a real key and redeploy `extractOnboardingProfile`
- [ ] Set `ONBOARDING_AI_REVIEW_UIDS` for App Review accounts
- [ ] Confirm App Check / TestFlight attestation in Firebase Console
- [ ] Finish TestFlight upload if `scripts/deploy_testflight.sh` is still running / re-run after CI green
