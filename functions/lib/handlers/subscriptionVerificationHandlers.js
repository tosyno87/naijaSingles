"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.verifySubscriptionPurchase = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const google_auth_library_1 = require("google-auth-library");
const REGION = 'us-central1';
exports.verifySubscriptionPurchase = (0, https_1.onCall)({ region: REGION }, async (request) => {
    if (!request.auth?.uid) {
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = request.auth.uid;
    const platform = (request.data?.platform ?? '').toLowerCase();
    const productId = request.data?.productId ?? '';
    const packageName = request.data?.packageName ?? 'com.app.naijasingles';
    const purchaseToken = request.data?.purchaseToken;
    const receiptData = request.data?.receiptData;
    if (!platform || !productId) {
        throw new https_1.HttpsError('invalid-argument', 'platform and productId are required');
    }
    const allowUnverified = (process.env.IAP_ALLOW_UNVERIFIED_SYNC ?? '').toLowerCase() === 'true';
    let verified = false;
    let expiresAt = null;
    if (platform === 'android') {
        if (!purchaseToken) {
            throw new https_1.HttpsError('invalid-argument', 'purchaseToken required for Android');
        }
        const saJson = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
        if (saJson) {
            try {
                const auth = new google_auth_library_1.GoogleAuth({
                    credentials: JSON.parse(saJson),
                    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
                });
                const client = await auth.getClient();
                const url = 'https://androidpublisher.googleapis.com/androidpublisher/v3/' +
                    `applications/${encodeURIComponent(packageName)}` +
                    '/purchases/subscriptions/' +
                    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
                const res = await client.request({ url });
                const ms = res.data.expiryTimeMillis;
                if (ms) {
                    verified = true;
                    expiresAt = admin.firestore.Timestamp.fromMillis(parseInt(ms, 10));
                }
            }
            catch (e) {
                console.error(JSON.stringify({ event: 'play_verify_error', err: String(e) }));
                if (!allowUnverified) {
                    throw new https_1.HttpsError('internal', 'Google Play subscription verification failed');
                }
            }
        }
        else if (allowUnverified) {
            verified = false;
        }
        else {
            throw new https_1.HttpsError('failed-precondition', 'Google Play verification not configured (set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON)');
        }
    }
    else if (platform === 'ios') {
        if (!receiptData) {
            throw new https_1.HttpsError('invalid-argument', 'receiptData required for iOS');
        }
        const secret = process.env.ITUNES_SHARED_SECRET;
        if (secret) {
            try {
                let resp = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        'receipt-data': receiptData,
                        password: secret,
                        'exclude-old-transactions': true,
                    }),
                });
                let body = (await resp.json());
                if (body.status === 21007) {
                    resp = await fetch('https://sandbox.itunes.apple.com/verifyReceipt', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            'receipt-data': receiptData,
                            password: secret,
                            'exclude-old-transactions': true,
                        }),
                    });
                    body = (await resp.json());
                }
                if (body.status === 0 && body.latest_receipt_info?.length) {
                    const info = body.latest_receipt_info.find((x) => x.product_id === productId);
                    if (info?.expires_date_ms) {
                        verified = true;
                        expiresAt = admin.firestore.Timestamp.fromMillis(parseInt(info.expires_date_ms, 10));
                    }
                }
            }
            catch (e) {
                console.error(JSON.stringify({ event: 'apple_verify_error', err: String(e) }));
                if (!allowUnverified) {
                    throw new https_1.HttpsError('internal', 'App Store subscription verification failed');
                }
            }
        }
        else if (allowUnverified) {
            verified = false;
        }
        else {
            throw new https_1.HttpsError('failed-precondition', 'App Store verification not configured (set ITUNES_SHARED_SECRET)');
        }
    }
    else {
        throw new https_1.HttpsError('invalid-argument', 'platform must be ios or android');
    }
    const db = admin.firestore();
    const ref = db.collection('users').doc(uid);
    const update = {
        isPremium: true,
        subscriptionPlanId: productId,
        subscriptionStore: platform,
        subscriptionLastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        subscriptionDate: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (expiresAt) {
        update.subscriptionExpiresAt = expiresAt;
    }
    if (!verified && allowUnverified) {
        update.entitlementUnverified = true;
    }
    else {
        update.entitlementUnverified = admin.firestore.FieldValue.delete();
    }
    await ref.set(update, { merge: true });
    return {
        verified,
        message: verified ?
            'Subscription verified' :
            allowUnverified ?
                'Subscription recorded (unverified mode)' :
                'Subscription updated',
    };
});
//# sourceMappingURL=subscriptionVerificationHandlers.js.map