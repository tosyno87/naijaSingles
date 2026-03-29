/**
 * Callable HTTPS: start / confirm account deletion OTP, then Admin deleteUser.
 */

import {createHash} from 'crypto';
import * as admin from 'firebase-admin';
import {onCall, HttpsError, CallableRequest} from 'firebase-functions/v2/https';
import {generateNumericOtp, hashOtp, verifyOtp} from '../services/accountDeletionOtpCrypto';
import {sendDeletionOtpEmail} from '../services/accountDeletionMessaging';

const REGION = 'us-central1';

/** When false, App Check is not enforced on deletion callables (dev/staging only). */
const ENFORCE_APPCHECK =
  (process.env.ACCOUNT_DELETION_ENFORCE_APPCHECK ?? 'true').toLowerCase() !==
  'false';

// One log per cold start so operators can confirm App Check gate in Cloud Logging.
console.log(
  JSON.stringify({
    event: 'account_deletion_callable_config',
    enforceAppCheck: ENFORCE_APPCHECK,
    ts: new Date().toISOString(),
  })
);

/** Fresh phone re-auth must be within this window (client PhoneAuth only). */
const PHONE_PROOF_MAX_AGE_SEC = 5 * 60;

const OTP_TTL_MS = 10 * 60 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_ATTEMPTS = 5;
const LOCKOUT_MS = 15 * 60 * 1000;

const VERIFICATIONS = 'accountDeletionVerifications';
const ABUSE = 'accountDeletionAbuse';

/** Rolling window for per-IP callable abuse caps. */
const IP_WINDOW_MS = 60 * 60 * 1000;
const MAX_START_OTP_PER_IP_PER_WINDOW = 40;
const MAX_CONFIRM_OTP_PER_IP_PER_WINDOW = 80;
const MAX_PHONE_PROOF_PER_IP_PER_WINDOW = 40;
/** Direct delete (no OTP): separate bucket from phoneProof for accurate limits/metrics. */
const MAX_DIRECT_DELETE_PER_IP_PER_WINDOW = 40;

/**
 * Sliding retention for `accountDeletionAbuse` docs so the collection does not grow
 * without bound. Enable a Firestore TTL policy on field [expireAt] for this collection.
 */
const ABUSE_DOC_TTL_MS = 7 * 24 * 60 * 60 * 1000;

function logMetric(
  event: string,
  payload: Record<string, unknown> = {}
): void {
  console.log(
    JSON.stringify({
      event,
      ...payload,
      ts: new Date().toISOString(),
    })
  );
}

function logDeletionRisk(payload: Record<string, unknown>): void {
  console.log(
    JSON.stringify({
      event: 'account_deletion_risk',
      ...payload,
      ts: new Date().toISOString(),
    })
  );
}

function getPepper(): string {
  const p = process.env.DELETION_OTP_PEPPER?.trim();
  if (!p || p.length < 16) {
    throw new HttpsError(
      'failed-precondition',
      'Server misconfiguration: DELETION_OTP_PEPPER'
    );
  }
  return p;
}

function inferAuthProvider(user: admin.auth.UserRecord): string {
  const ids = user.providerData.map((p) => p.providerId);
  if (ids.includes('phone')) return 'phone';
  if (ids.includes('password')) return 'email';
  if (ids.some((id) => id.includes('google'))) return 'google';
  return 'other';
}

function hashIp(ip: string): string {
  return createHash('sha256').update(ip).digest('hex');
}

/** Exported for unit tests (Express-style rawRequest shapes). */
export function extractClientIp(request: CallableRequest): string | null {
  const raw = request.rawRequest;
  if (!raw || typeof raw !== 'object') {
    return null;
  }
  const req = raw as {
    get?: (name: string) => string | undefined;
    socket?: {remoteAddress?: string};
    ip?: string;
  };
  if (typeof req.get === 'function') {
    const xff = req.get('x-forwarded-for');
    if (xff) {
      const first = xff.split(',')[0]?.trim();
      if (first) {
        return first;
      }
    }
  }
  if (req.ip) {
    return req.ip;
  }
  return req.socket?.remoteAddress ?? null;
}

function ipHashShort(ip: string): string {
  return hashIp(ip).slice(0, 16);
}

type AbuseKind = 'startOtp' | 'confirmOtp' | 'phoneProof' | 'directDelete';

async function enforceIpDeletionLimit(
  db: admin.firestore.Firestore,
  ip: string,
  kind: AbuseKind
): Promise<void> {
  const key = hashIp(ip);
  const ref = db.collection(ABUSE).doc(key);
  const max =
    kind === 'startOtp'
      ? MAX_START_OTP_PER_IP_PER_WINDOW
      : kind === 'confirmOtp'
        ? MAX_CONFIRM_OTP_PER_IP_PER_WINDOW
        : kind === 'phoneProof'
          ? MAX_PHONE_PROOF_PER_IP_PER_WINDOW
          : MAX_DIRECT_DELETE_PER_IP_PER_WINDOW;
  const countField =
    kind === 'startOtp'
      ? 'startOtpCount'
      : kind === 'confirmOtp'
        ? 'confirmOtpCount'
        : kind === 'phoneProof'
          ? 'phoneProofCount'
          : 'directDeleteCount';
  const windowField =
    kind === 'startOtp'
      ? 'startOtpWindowAt'
      : kind === 'confirmOtp'
        ? 'confirmOtpWindowAt'
        : kind === 'phoneProof'
          ? 'phoneProofWindowAt'
          : 'directDeleteWindowAt';

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() ?? {};
    const now = Date.now();
    let windowStart = (
      data[windowField] as admin.firestore.Timestamp | undefined
    )?.toMillis() ?? 0;
    let count = (data[countField] as number) ?? 0;
    if (now - windowStart > IP_WINDOW_MS) {
      windowStart = now;
      count = 0;
    }
    count += 1;
    if (count > max) {
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil((windowStart + IP_WINDOW_MS - now) / 1000)
      );
      throw new HttpsError(
        'resource-exhausted',
        'Too many requests from this network. Try again later.',
        {retryAfterSeconds}
      );
    }
    tx.set(
      ref,
      {
        [windowField]: admin.firestore.Timestamp.fromMillis(windowStart),
        [countField]: count,
        ipHashShort: ipHashShort(ip),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        expireAt: admin.firestore.Timestamp.fromMillis(now + ABUSE_DOC_TTL_MS),
      },
      {merge: true}
    );
  });
}

function scrubClientMeta(
  raw: unknown
): Record<string, string> | undefined {
  if (raw == null || typeof raw !== 'object') {
    return undefined;
  }
  const o = raw as Record<string, unknown>;
  const platform = o.platform != null ? String(o.platform).slice(0, 32) : '';
  const appVersion =
    o.appVersion != null ? String(o.appVersion).slice(0, 32) : '';
  if (!platform && !appVersion) {
    return undefined;
  }
  const out: Record<string, string> = {};
  if (platform) {
    out.platform = platform;
  }
  if (appVersion) {
    out.appVersion = appVersion;
  }
  return out;
}

export type AccountDeletionCallableRequest = {
  auth?: {uid: string} | null;
  data?: unknown;
  rawRequest?: CallableRequest['rawRequest'];
  app?: CallableRequest['app'];
};

/** Exported for unit tests (invoke with mocked `firebase-admin`). */
export async function startDeletionOtpHandler(
  request: AccountDeletionCallableRequest
): Promise<Record<string, unknown>> {
  const cr = request as CallableRequest;
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required');
  }
  const uid = request.auth.uid;
  const payload = (request.data ?? {}) as Record<string, unknown>;
  const channelRaw = payload.channel as string | undefined;
  const channel = channelRaw ?? 'email';
  if (channel !== 'email') {
    throw new HttpsError(
      'invalid-argument',
      'Use email for this step. Phone accounts verify with a text code in the app, then confirm deletion.'
    );
  }

  const auth = admin.auth();
  const user = await auth.getUser(uid);
  const db = admin.firestore();
  const clientMeta = scrubClientMeta(payload.clientMeta);
  const ip = extractClientIp(cr);
  if (ip) {
    await enforceIpDeletionLimit(db, ip, 'startOtp');
  }
  logDeletionRisk({
    callable: 'startDeletionOtp',
    uid,
    ipHashShort: ip ? ipHashShort(ip) : null,
    appCheck: cr.app != null ? 'present' : 'absent',
    clientMeta,
  });

  const ref = db.collection(VERIFICATIONS).doc(uid);
  const now = Date.now();
  const pepper = getPepper();

  const snap = await ref.get();
  const data = snap.data();

  if (data?.lockedUntil) {
    const lockedUntil = data.lockedUntil as admin.firestore.Timestamp;
    if (lockedUntil.toMillis() > now) {
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil((lockedUntil.toMillis() - now) / 1000)
      );
      throw new HttpsError(
        'resource-exhausted',
        'Too many incorrect codes. Try again later.',
        {retryAfterSeconds}
      );
    }
  }

  if (data?.lastSentAt) {
    const last = (data.lastSentAt as admin.firestore.Timestamp).toMillis();
    if (now - last < RESEND_COOLDOWN_MS) {
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil((RESEND_COOLDOWN_MS - (now - last)) / 1000)
      );
      throw new HttpsError(
        'resource-exhausted',
        'Please wait before requesting another code.',
        {retryAfterSeconds}
      );
    }
  }

  if (!user.email) {
    throw new HttpsError(
      'failed-precondition',
      'No email on this account to send a code to.'
    );
  }
  const destination = maskEmail(user.email);

  const code = generateNumericOtp();
  const {saltB64, hashB64} = hashOtp(code, pepper);
  const expiresAt = admin.firestore.Timestamp.fromMillis(now + OTP_TTL_MS);

  const nextResend = (data?.resendCount as number | undefined) ?? 0;

  await ref.set(
    {
      uid,
      channel,
      codeHash: hashB64,
      salt: saltB64,
      expiresAt,
      attemptCount: 0,
      resendCount: nextResend + 1,
      lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
      lockedUntil: admin.firestore.FieldValue.delete(),
      consumedAt: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  try {
    await sendDeletionOtpEmail({to: user.email, code});
    logMetric('account_deletion_otp_sent', {uid, channel: 'email'});
  } catch (err) {
    console.error('startDeletionOtp send failed', err);
    logMetric('account_deletion_otp_send_failed', {
      uid,
      channel,
      error: String((err as Error).message ?? err),
    });
    await ref.set(
      {
        sendErrorAt: admin.firestore.FieldValue.serverTimestamp(),
        sendErrorMessage: String((err as Error).message ?? err),
      },
      {merge: true}
    );
    throw new HttpsError(
      'internal',
      'Could not send your code. Try again or use another verification method.'
    );
  }

  return {
    ok: true,
    channel,
    destinationHint: destination,
    expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
  };
}

export const startDeletionOtp = onCall(
  {
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
  },
  startDeletionOtpHandler
);

/** Exported for unit tests (invoke with mocked `firebase-admin`). */
export async function confirmDeletionOtpHandler(
  request: AccountDeletionCallableRequest
): Promise<Record<string, unknown>> {
  const cr = request as CallableRequest;
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required');
  }
  const uid = request.auth.uid;
  const payload = (request.data ?? {}) as Record<string, unknown>;
  const code = String(payload.code ?? '').replace(/\D/g, '');
  const reasonRaw = String(payload.reason ?? '').trim();
  const customReason =
    payload.customReason != null ? String(payload.customReason).trim() : '';
  const clientMeta = scrubClientMeta(payload.clientMeta);

  if (code.length !== 6) {
    throw new HttpsError('invalid-argument', 'Enter the 6-digit code.');
  }
  if (customReason.length > 200) {
    throw new HttpsError('invalid-argument', 'Custom reason is too long.');
  }
  const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
  if (reason.length > 200) {
    throw new HttpsError('invalid-argument', 'Invalid deletion reason.');
  }

  const db = admin.firestore();
  const ip = extractClientIp(cr);
  if (ip) {
    await enforceIpDeletionLimit(db, ip, 'confirmOtp');
  }
  logDeletionRisk({
    callable: 'confirmDeletionOtp',
    uid,
    ipHashShort: ip ? ipHashShort(ip) : null,
    appCheck: cr.app != null ? 'present' : 'absent',
    clientMeta,
  });

  const vRef = db.collection(VERIFICATIONS).doc(uid);
  const pepper = getPepper();
  const auth = admin.auth();
  const user = await auth.getUser(uid);
  const authProvider = inferAuthProvider(user);

  const snap = await vRef.get();
  if (!snap.exists) {
    throw new HttpsError(
      'not-found',
      'No active verification. Request a new code.'
    );
  }
  const v = snap.data()!;
  const now = Date.now();

  if (v.channel != null && v.channel !== 'email') {
    throw new HttpsError(
      'failed-precondition',
      'Request a new email code to continue.'
    );
  }

  if (v.consumedAt) {
    throw new HttpsError(
      'failed-precondition',
      'This code was already used. Request a new code.'
    );
  }

  if (v.lockedUntil) {
    const lockedUntil = (v.lockedUntil as admin.firestore.Timestamp).toMillis();
    if (lockedUntil > now) {
      const retryAfterSeconds = Math.max(
        1,
        Math.ceil((lockedUntil - now) / 1000)
      );
      throw new HttpsError(
        'resource-exhausted',
        'Too many incorrect codes. Try again later.',
        {retryAfterSeconds}
      );
    }
  }

  const expiresAt = v.expiresAt as admin.firestore.Timestamp;
  if (expiresAt.toMillis() < now) {
    throw new HttpsError(
      'failed-precondition',
      'Code expired. Request a new one.'
    );
  }

  const ok = verifyOtp(
    code,
    pepper,
    v.salt as string,
    v.codeHash as string
  );
  const prevAttempts = (v.attemptCount as number) ?? 0;
  const attempts = prevAttempts + 1;

  if (!ok) {
    const updates: Record<string, unknown> = {
      attemptCount: attempts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (attempts >= MAX_ATTEMPTS) {
      updates.lockedUntil = admin.firestore.Timestamp.fromMillis(
        now + LOCKOUT_MS
      );
    }
    await vRef.set(updates, {merge: true});
    logMetric('account_deletion_otp_confirm_fail', {
      uid,
      reason: 'bad_code',
      attempts,
    });
    const attemptsRemaining = Math.max(0, MAX_ATTEMPTS - attempts);
    if (attempts >= MAX_ATTEMPTS) {
      throw new HttpsError(
        'resource-exhausted',
        'Too many incorrect codes. Try again later.',
        {retryAfterSeconds: Math.ceil(LOCKOUT_MS / 1000), attemptsRemaining: 0}
      );
    }
    throw new HttpsError(
      'permission-denied',
      'That code does not match. Check and try again.',
      {attemptsRemaining}
    );
  }

  await db.runTransaction(async (tx) => {
    const s = await tx.get(vRef);
    if (!s.exists) {
      throw new HttpsError(
        'not-found',
        'No active verification. Request a new code.'
      );
    }
    const fresh = s.data()!;
    if (fresh.consumedAt) {
      throw new HttpsError(
        'failed-precondition',
        'This code was already used. Request a new code.'
      );
    }
    const stillOk = verifyOtp(
      code,
      pepper,
      fresh.salt as string,
      fresh.codeHash as string
    );
    if (!stillOk) {
      const attemptsRemaining = Math.max(
        0,
        MAX_ATTEMPTS - ((fresh.attemptCount as number) ?? 0) - 1
      );
      throw new HttpsError(
        'permission-denied',
        'That code does not match. Check and try again.',
        {attemptsRemaining}
      );
    }

    tx.set(
      vRef,
      {
        consumedAt: admin.firestore.FieldValue.serverTimestamp(),
        attemptCount: attempts,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    const auditRef = db.collection('accountDeletions').doc(uid);
    tx.set(
      auditRef,
      {
        userId: uid,
        email: user.email ?? null,
        phoneNumber: user.phoneNumber ?? null,
        authProvider,
        reason,
        customReason: customReason.length > 0 ? customReason : null,
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        otpVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        otpChannel: 'email',
        otpConfirmAttempts: attempts,
      },
      {merge: true}
    );
  });

  try {
    await auth.deleteUser(uid);
    logMetric('account_deletion_confirm_ok', {uid, method: 'email_otp'});
  } catch (err) {
    console.error('confirmDeletionOtp deleteUser failed', err);
    logMetric('account_deletion_auth_delete_failed', {
      uid,
      error: String((err as Error).message ?? err),
    });
    const auditRef = db.collection('accountDeletions').doc(uid);
    await auditRef.set(
      {
        status: 'failed',
        failureStage: 'auth_delete',
        failureMessage: String((err as Error).message ?? err),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    throw new HttpsError(
      'internal',
      'Could not complete account deletion. Please contact support.'
    );
  }

  return {ok: true};
}

export const confirmDeletionOtp = onCall(
  {
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
  },
  confirmDeletionOtpHandler
);

/**
 * After client phone re-verification, verifies a fresh ID token
 * (phone provider + recent auth_time) and deletes the user.
 */
export async function confirmDeletionAfterPhoneProofHandler(
  request: AccountDeletionCallableRequest
): Promise<Record<string, unknown>> {
  const cr = request as CallableRequest;
  const payload = (request.data ?? {}) as Record<string, unknown>;
  const idToken = String(payload.idToken ?? '').trim();
  const reasonRaw = String(payload.reason ?? '').trim();
  const customReason =
    payload.customReason != null ? String(payload.customReason).trim() : '';
  const clientMeta = scrubClientMeta(payload.clientMeta);

  if (!idToken) {
    throw new HttpsError('invalid-argument', 'Missing session proof.');
  }
  if (customReason.length > 200) {
    throw new HttpsError('invalid-argument', 'Custom reason is too long.');
  }
  const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
  if (reason.length > 200) {
    throw new HttpsError('invalid-argument', 'Invalid deletion reason.');
  }

  const auth = admin.auth();
  let decoded: admin.auth.DecodedIdToken;
  try {
    decoded = await auth.verifyIdToken(idToken, true);
  } catch {
    throw new HttpsError(
      'permission-denied',
      'Invalid or expired session. Verify your phone again.'
    );
  }
  const uid = decoded.uid;

  const db = admin.firestore();
  const ip = extractClientIp(cr);
  if (ip) {
    await enforceIpDeletionLimit(db, ip, 'phoneProof');
  }
  logDeletionRisk({
    callable: 'confirmDeletionAfterPhoneProof',
    uid,
    ipHashShort: ip ? ipHashShort(ip) : null,
    appCheck: cr.app != null ? 'present' : 'absent',
    clientMeta,
    callableAuthPresent: request.auth != null,
  });

  const signInProvider = decoded.firebase?.sign_in_provider;
  if (signInProvider !== 'phone') {
    throw new HttpsError(
      'failed-precondition',
      'Recent phone verification required. Finish the text code step in the app.'
    );
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (nowSec - decoded.auth_time > PHONE_PROOF_MAX_AGE_SEC) {
    throw new HttpsError(
      'failed-precondition',
      'Verification expired. Request a new code and try again.'
    );
  }

  const user = await auth.getUser(uid);
  if (!user.phoneNumber) {
    throw new HttpsError(
      'failed-precondition',
      'No phone number on this account.'
    );
  }

  const authProvider = inferAuthProvider(user);
  const auditRef = db.collection('accountDeletions').doc(uid);

  await auditRef.set(
    {
      userId: uid,
      email: user.email ?? null,
      phoneNumber: user.phoneNumber ?? null,
      authProvider,
      reason,
      customReason: customReason.length > 0 ? customReason : null,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      verificationMethod: 'firebase_phone',
      phoneProofVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  try {
    await auth.deleteUser(uid);
    logMetric('account_deletion_confirm_ok', {uid, method: 'phone_proof'});
  } catch (err) {
    console.error('confirmDeletionAfterPhoneProof deleteUser failed', err);
    logMetric('account_deletion_auth_delete_failed', {
      uid,
      method: 'phone_proof',
      error: String((err as Error).message ?? err),
    });
    await auditRef.set(
      {
        status: 'failed',
        failureStage: 'auth_delete',
        failureMessage: String((err as Error).message ?? err),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    throw new HttpsError(
      'internal',
      'Could not complete account deletion. Please contact support.'
    );
  }

  return {ok: true};
}

export const confirmDeletionAfterPhoneProof = onCall(
  {
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
  },
  confirmDeletionAfterPhoneProofHandler
);

/**
 * Direct account deletion for signed-in users (no OTP challenge).
 * Verifies ID token and deletes immediately.
 */
export async function deleteAccountDirectHandler(
  request: AccountDeletionCallableRequest
): Promise<Record<string, unknown>> {
  const cr = request as CallableRequest;
  const payload = (request.data ?? {}) as Record<string, unknown>;
  const idToken = String(payload.idToken ?? '').trim();
  const reasonRaw = String(payload.reason ?? '').trim();
  const customReason =
    payload.customReason != null ? String(payload.customReason).trim() : '';
  const clientMeta = scrubClientMeta(payload.clientMeta);

  if (!idToken) {
    throw new HttpsError('invalid-argument', 'Missing session proof.');
  }
  if (customReason.length > 200) {
    throw new HttpsError('invalid-argument', 'Custom reason is too long.');
  }
  const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
  if (reason.length > 200) {
    throw new HttpsError('invalid-argument', 'Invalid deletion reason.');
  }

  const auth = admin.auth();
  let decoded: admin.auth.DecodedIdToken;
  try {
    decoded = await auth.verifyIdToken(idToken, true);
  } catch {
    throw new HttpsError(
      'permission-denied',
      'Invalid or expired session. Please sign in again.'
    );
  }
  const uid = decoded.uid;

  if (request.auth?.uid && request.auth.uid !== uid) {
    throw new HttpsError(
      'permission-denied',
      'Session does not match the signed-in account.'
    );
  }

  const db = admin.firestore();
  const ip = extractClientIp(cr);
  if (ip) {
    await enforceIpDeletionLimit(db, ip, 'directDelete');
  }
  logDeletionRisk({
    callable: 'deleteAccountDirect',
    uid,
    ipHashShort: ip ? ipHashShort(ip) : null,
    appCheck: cr.app != null ? 'present' : 'absent',
    callableAuthPresent: request.auth?.uid != null,
    clientMeta,
  });

  const user = await auth.getUser(uid);
  const authProvider = inferAuthProvider(user);
  const auditRef = db.collection('accountDeletions').doc(uid);

  await auditRef.set(
    {
      userId: uid,
      email: user.email ?? null,
      phoneNumber: user.phoneNumber ?? null,
      authProvider,
      reason,
      customReason: customReason.length > 0 ? customReason : null,
      requestedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
      verificationMethod: 'active_session',
      sessionVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  try {
    await auth.deleteUser(uid);
    logMetric('account_deletion_confirm_ok', {uid, method: 'direct'});
  } catch (err) {
    console.error('deleteAccountDirect deleteUser failed', err);
    logMetric('account_deletion_auth_delete_failed', {
      uid,
      method: 'direct',
      error: String((err as Error).message ?? err),
    });
    await auditRef.set(
      {
        status: 'failed',
        failureStage: 'auth_delete',
        failureMessage: String((err as Error).message ?? err),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );
    throw new HttpsError(
      'internal',
      'Could not complete account deletion. Please contact support.'
    );
  }

  return {ok: true};
}

export const deleteAccountDirect = onCall(
  {
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
  },
  deleteAccountDirectHandler
);

function maskEmail(email: string): string {
  const [a, domain] = email.split('@');
  if (!domain) return '***';
  const head = a.slice(0, 2);
  return `${head}***@${domain}`;
}
