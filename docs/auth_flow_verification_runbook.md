# Auth flow verification runbook (Google + Phone)

Use this checklist to validate auth behavior on device or emulator before release. Auth method, success/failure, and routing outcome are logged (e.g. AuthRouter, GoogleLoginBloc, RegistrationBloc) for production debugging.

## Scope

- **Providers:** Google and Phone only (no Apple, no Email on create-account screen).
- **Post-auth:** Both providers ensure `users/{uid}` exists (minimal doc for new users), then route via `AuthRouter.navigateAfterAuth` to onboarding (incomplete profile) or main (complete profile).
- **Phone OTP:** The only supported phone flow is **PhoneNumber → OtpPage** (with `isLogin` and duplicate-account handling). The legacy path (PhoneVerificationScreen / OtpVerificationScreen) has been retired.

## Device-level checklist

1. **New Google user**
   - Sign in with Google (create-account or sign-in screen).
   - Expect: user doc created, then navigation to onboarding (incomplete) or main (if doc already complete).
   - Verify: no crash; back button does not return to auth.

2. **Returning Google user**
   - Sign in with Google using an account that already has a complete profile.
   - Expect: user doc updated, navigation to main.
   - Verify: no duplicate onboarding.

3. **New Phone user**
   - Enter phone, receive OTP, verify.
   - Expect: minimal user doc created, then navigation to onboarding.
   - Verify: no crash; routing via same path as Google.

4. **Returning Phone user (complete profile)**
   - Sign in with phone that already has a complete profile.
   - Expect: navigation to main.
   - Verify: UserBloc updated, main screen shows.

5. **Returning Phone user (incomplete profile)**
   - Sign in with phone that has a user doc but profile incomplete.
   - Expect: navigation to onboarding (AuthRouter reads doc and routes by completeness).

6. **Onboarding incomplete vs complete**
   - For both Google and Phone: confirm that after first-time sign-in, destination is onboarding; after completing onboarding and signing out then back in, destination is main.

7. **Network failure during auth**
   - Turn off network (or use airplane mode) before or during sign-in.
   - Expect: clear error message (e.g. "Could not complete sign in. Please try again." or "No Internet Connection"); no navigation to main/onboarding on failure.

8. **Failure during profile reconciliation**
   - Simulate Firestore unreachable after Google sign-in (e.g. turn off network after tapping Google but before doc write).
   - Expect: error message, no navigation; user can retry.

9. **Phone: duplicate number**
   - Sign up with a phone number already registered to another account.
   - Expect: message "This phone number is already registered. Please sign in instead." and sign-out/pop.

10. **Phone: login with unregistered number**
    - On sign-in flow, enter a phone number that has never been registered.
    - Expect: after OTP verify, message "No account found with this phone number. Please sign up first." and pop.

## Quick smoke (minimum before release)

- New Google user → onboarding.
- Returning Google user → main.
- New Phone user → onboarding.
- Returning Phone user (complete) → main.
- One failure path (e.g. cancel Google or invalid OTP) shows error and does not navigate.
