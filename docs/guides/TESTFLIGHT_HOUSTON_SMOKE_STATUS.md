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
| `flutter build ipa` archive | Stale / do not upload | Prior archive was 1.0.1+16 with Apple Development signing; may lack `ENV=production` dart-define. Rebuild via `./scripts/deploy_testflight.sh --build-only` before upload. |
| TestFlight IPA export / upload | Blocked | Needs Apple Distribution cert + App Store profile. After device verify, upload the **same** IPA with `./scripts/deploy_testflight.sh --upload-only PATH.ipa` (or Organizer on that archive) — do not full-redeploy. |

## Human smoke (post TestFlight / signed-in)

1. [x] Fresh install → auth → **Discover** (auto-login as Lisa Lopez / Houston test user on sim, `ENV=production`)
2. [x] Discover: Houston hero (“New in Houston?”) + weekend event (“Sunday Brunch & Connect”) + Explore groups CTA — screenshot `.playtest-houston/smoke/05_after_login.png`
3. [x] Soft Connect CTA / Connect tab reachable (integration smoke tapped Connect → Messages → Discover)
4. [ ] AI unavailable / review UID → Fill it in myself → Discover
5. [ ] Messages still opens existing match chat (tab opens; thread content not asserted)
6. [ ] App Review screenshots in order from `APP_REVIEW_CONVERSATIONAL_ONBOARDING.md`

Sim smoke command (debug): `flutter test integration_test/houston_smoke_autologin_test.dart -d <sim> --dart-define=ENV=production --dart-define=ENABLE_AUTO_LOGIN=true --dart-define=TEST_EMAIL=… --dart-define=TEST_PASSWORD=…`

## Operator leftovers

- [x] `OPENAI_API_KEY` set on `naijasingles-74a75` + `extractOnboardingProfile` redeployed (OpenAI org still needs billing credits — API returned 429)
- [ ] Set `ONBOARDING_AI_REVIEW_UIDS` for App Review accounts
- [ ] Confirm App Check / TestFlight attestation in Firebase Console
- [ ] Install Apple Distribution certificate + App Store provisioning for `com.app.naijasingles`
- [ ] After `--build-only` + device launch OK: `./scripts/deploy_testflight.sh --upload-only PATH.ipa` or Organizer → Distribute on that same archive
- [ ] Capture App Review screenshots after sign-in (onboarding → Discover → event/group)
