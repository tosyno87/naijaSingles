# Subscription & IAP sandbox checklist

Use this before promoting a release that touches in-app purchases or `verifySubscriptionPurchase`.

## Preconditions

- **Cloud Function** `verifySubscriptionPurchase` is deployed to the same Firebase project as the app build.
- **Firestore rules** allow only the server to write entitlement fields on `users/{uid}` (`isPremium`, `subscriptionExpiresAt`, etc.).
- **Android**: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` is set on the function; Play Console linked; `AppConfig.androidApplicationId` matches the Play app id.
- **iOS**: `ITUNES_SHARED_SECRET` is set on the function; App Store Connect product IDs match Firestore `Packages` (`iosProductId` / `androidProductId` or legacy `id`).

## Store consoles

- [ ] Products exist and are **Approved** / **Active** for the target track (internal testing at minimum).
- [ ] License testers (Android) and sandbox testers (iOS) are configured.
- [ ] **Firestore `Packages`**: each active package has the correct platform product id and `status`/active flags as expected by `InAppPurchaseRepoImpl`.

## Client flows (each on a real device or sandbox)

- [ ] **Paywall load**: plans appear; empty catalog shows retry and logs show `Packages` diagnostics if misconfigured.
- [ ] **New purchase**: pending UI → success only after server verification and user doc refresh.
- [ ] **Restore** (Account Settings): progress dialog → snackbar (restored, nothing found, or error) matches outcome.
- [ ] **Manage subscription**: store URL opens; if `canLaunchUrl` is false, copy-link dialog appears.
- [ ] **Premium-gated feature** (e.g. super likes): respects `UserModel.hasPremiumAccess` after sync.

## Backend / renewals

- [ ] **Renewal** (sandbox accelerated): `subscriptionExpiresAt` updates after verification path runs again.
- [ ] **Cancellation**: app reflects loss of access when the store reports expiry (after next verification).
- [ ] **Refund** (if testable): entitlement clears when verification no longer returns active.

## Rollout note

- **`SUBSCRIPTION_VERIFY_ROLLOUT`**: defaults to `true`. If you pass `--dart-define=SUBSCRIPTION_VERIFY_ROLLOUT=false`, the client will **not** call the verifier and purchases will surface an error—use only for local experiments, not production.
- Entitlement updates require the callable and tightened rules; do not ship a build that writes `isPremium` from the client.

## Analytics & logging (client)

Firebase Analytics events (see `SubscriptionIapAnalytics`):

| Event | When |
|--------|------|
| `iap_verify_failed` | Callable / verification throws after purchase or restore |
| `iap_verify_succeeded` | Server verification + `completePurchase` (if needed) succeeded |
| `iap_restore_outcome` | Restore UX terminal state: `success`, `timeout`, `verify_failed`, `store_unavailable`, `native_exception` |
| `iap_purchase_failed` | Store `PurchaseStatus.error` |
| `iap_purchase_stream_error` | `purchaseStream` error from the plugin |

Verify failures also emit a **non-fatal** Crashlytics error and breadcrumb logs. Device logs use `AppLogger` (`iap_*` prefixes) for support when Analytics is unavailable.
