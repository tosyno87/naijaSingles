/**
 * Verifies IAP subscriptions server-side and writes entitlement fields on users/{uid}.
 *
 * Env (production):
 * - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON: service account JSON (Android subscriptions v2 API)
 * - ITUNES_SHARED_SECRET: App Store shared secret for verifyReceipt (legacy; StoreKit2/JWS may need App Store Server API)
 *
 * Dev / staging escape hatch:
 * - IAP_ALLOW_UNVERIFIED_SYNC=true — records premium with entitlementUnverified (never use in production)
 */
interface VerifyPayload {
    platform?: string;
    productId?: string;
    packageName?: string;
    purchaseToken?: string;
    receiptData?: string;
}
export declare const verifySubscriptionPurchase: import("firebase-functions/v2/https").CallableFunction<VerifyPayload, Promise<{
    verified: boolean;
    message: string;
}>, unknown>;
export {};
//# sourceMappingURL=subscriptionVerificationHandlers.d.ts.map