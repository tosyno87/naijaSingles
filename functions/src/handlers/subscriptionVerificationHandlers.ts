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

import * as admin from 'firebase-admin';
import {onCall, HttpsError, CallableRequest} from 'firebase-functions/v2/https';
import {GoogleAuth} from 'google-auth-library';

const REGION = 'us-central1';

interface VerifyPayload {
  platform?: string;
  productId?: string;
  packageName?: string;
  purchaseToken?: string;
  receiptData?: string;
}

export const verifySubscriptionPurchase = onCall(
  {region: REGION},
  async (request: CallableRequest<VerifyPayload>) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = request.auth.uid;
    const platform = (request.data?.platform ?? '').toLowerCase();
    const productId = request.data?.productId ?? '';
    const packageName =
      request.data?.packageName ?? 'com.app.naijasingles';
    const purchaseToken = request.data?.purchaseToken;
    const receiptData = request.data?.receiptData;

    if (!platform || !productId) {
      throw new HttpsError(
        'invalid-argument',
        'platform and productId are required',
      );
    }

    const allowUnverified =
      (process.env.IAP_ALLOW_UNVERIFIED_SYNC ?? '').toLowerCase() === 'true';

    let verified = false;
    let expiresAt: admin.firestore.Timestamp | null = null;

    if (platform === 'android') {
      if (!purchaseToken) {
        throw new HttpsError(
          'invalid-argument',
          'purchaseToken required for Android',
        );
      }
      const saJson = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON;
      if (saJson) {
        try {
          const auth = new GoogleAuth({
            credentials: JSON.parse(saJson) as object,
            scopes: ['https://www.googleapis.com/auth/androidpublisher'],
          });
          const client = await auth.getClient();
          const url =
            'https://androidpublisher.googleapis.com/androidpublisher/v3/' +
            `applications/${encodeURIComponent(packageName)}` +
            '/purchases/subscriptions/' +
            `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
          const res = await client.request<{expiryTimeMillis?: string}>({url});
          const ms = res.data.expiryTimeMillis;
          if (ms) {
            verified = true;
            expiresAt = admin.firestore.Timestamp.fromMillis(parseInt(ms, 10));
          }
        } catch (e) {
          console.error(JSON.stringify({event: 'play_verify_error', err: String(e)}));
          if (!allowUnverified) {
            throw new HttpsError(
              'internal',
              'Google Play subscription verification failed',
            );
          }
        }
      } else if (allowUnverified) {
        verified = false;
      } else {
        throw new HttpsError(
          'failed-precondition',
          'Google Play verification not configured (set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON)',
        );
      }
    } else if (platform === 'ios') {
      if (!receiptData) {
        throw new HttpsError(
          'invalid-argument',
          'receiptData required for iOS',
        );
      }
      const secret = process.env.ITUNES_SHARED_SECRET;
      if (secret) {
        try {
          let resp = await fetch('https://buy.itunes.apple.com/verifyReceipt', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({
              'receipt-data': receiptData,
              password: secret,
              'exclude-old-transactions': true,
            }),
          });
          let body = (await resp.json()) as {
            status: number;
            latest_receipt_info?: Array<{
              expires_date_ms?: string;
              product_id?: string;
            }>;
          };
          if (body.status === 21007) {
            resp = await fetch('https://sandbox.itunes.apple.com/verifyReceipt', {
              method: 'POST',
              headers: {'Content-Type': 'application/json'},
              body: JSON.stringify({
                'receipt-data': receiptData,
                password: secret,
                'exclude-old-transactions': true,
              }),
            });
            body = (await resp.json()) as typeof body;
          }
          if (body.status === 0 && body.latest_receipt_info?.length) {
            const info = body.latest_receipt_info.find(
              (x) => x.product_id === productId,
            );
            if (info?.expires_date_ms) {
              verified = true;
              expiresAt = admin.firestore.Timestamp.fromMillis(
                parseInt(info.expires_date_ms, 10),
              );
            }
          }
        } catch (e) {
          console.error(JSON.stringify({event: 'apple_verify_error', err: String(e)}));
          if (!allowUnverified) {
            throw new HttpsError(
              'internal',
              'App Store subscription verification failed',
            );
          }
        }
      } else if (allowUnverified) {
        verified = false;
      } else {
        throw new HttpsError(
          'failed-precondition',
          'App Store verification not configured (set ITUNES_SHARED_SECRET)',
        );
      }
    } else {
      throw new HttpsError('invalid-argument', 'platform must be ios or android');
    }

    const db = admin.firestore();
    const ref = db.collection('users').doc(uid);
    const update: Record<string, unknown> = {
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
    } else {
      update.entitlementUnverified = admin.firestore.FieldValue.delete();
    }

    await ref.set(update, {merge: true});

    return {
      verified,
      message: verified ?
        'Subscription verified' :
        allowUnverified ?
          'Subscription recorded (unverified mode)' :
          'Subscription updated',
    };
  },
);
