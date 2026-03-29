"use strict";
/**
 * Callable HTTPS: start / confirm account deletion OTP, then Admin deleteUser.
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
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAccountDirect = exports.confirmDeletionAfterPhoneProof = exports.confirmDeletionOtp = exports.startDeletionOtp = void 0;
exports.extractClientIp = extractClientIp;
exports.startDeletionOtpHandler = startDeletionOtpHandler;
exports.confirmDeletionOtpHandler = confirmDeletionOtpHandler;
exports.confirmDeletionAfterPhoneProofHandler = confirmDeletionAfterPhoneProofHandler;
exports.deleteAccountDirectHandler = deleteAccountDirectHandler;
const crypto_1 = require("crypto");
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const accountDeletionOtpCrypto_1 = require("../services/accountDeletionOtpCrypto");
const accountDeletionMessaging_1 = require("../services/accountDeletionMessaging");
const REGION = 'us-central1';
/** When false, App Check is not enforced on deletion callables (dev/staging only). */
const ENFORCE_APPCHECK = ((_a = process.env.ACCOUNT_DELETION_ENFORCE_APPCHECK) !== null && _a !== void 0 ? _a : 'true').toLowerCase() !==
    'false';
// One log per cold start so operators can confirm App Check gate in Cloud Logging.
console.log(JSON.stringify({
    event: 'account_deletion_callable_config',
    enforceAppCheck: ENFORCE_APPCHECK,
    ts: new Date().toISOString(),
}));
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
function logMetric(event, payload = {}) {
    console.log(JSON.stringify(Object.assign(Object.assign({ event }, payload), { ts: new Date().toISOString() })));
}
function logDeletionRisk(payload) {
    console.log(JSON.stringify(Object.assign(Object.assign({ event: 'account_deletion_risk' }, payload), { ts: new Date().toISOString() })));
}
function getPepper() {
    var _a;
    const p = (_a = process.env.DELETION_OTP_PEPPER) === null || _a === void 0 ? void 0 : _a.trim();
    if (!p || p.length < 16) {
        throw new https_1.HttpsError('failed-precondition', 'Server misconfiguration: DELETION_OTP_PEPPER');
    }
    return p;
}
function inferAuthProvider(user) {
    const ids = user.providerData.map((p) => p.providerId);
    if (ids.includes('phone'))
        return 'phone';
    if (ids.includes('password'))
        return 'email';
    if (ids.some((id) => id.includes('google')))
        return 'google';
    return 'other';
}
function hashIp(ip) {
    return (0, crypto_1.createHash)('sha256').update(ip).digest('hex');
}
/** Exported for unit tests (Express-style rawRequest shapes). */
function extractClientIp(request) {
    var _a, _b, _c;
    const raw = request.rawRequest;
    if (!raw || typeof raw !== 'object') {
        return null;
    }
    const req = raw;
    if (typeof req.get === 'function') {
        const xff = req.get('x-forwarded-for');
        if (xff) {
            const first = (_a = xff.split(',')[0]) === null || _a === void 0 ? void 0 : _a.trim();
            if (first) {
                return first;
            }
        }
    }
    if (req.ip) {
        return req.ip;
    }
    return (_c = (_b = req.socket) === null || _b === void 0 ? void 0 : _b.remoteAddress) !== null && _c !== void 0 ? _c : null;
}
function ipHashShort(ip) {
    return hashIp(ip).slice(0, 16);
}
async function enforceIpDeletionLimit(db, ip, kind) {
    const key = hashIp(ip);
    const ref = db.collection(ABUSE).doc(key);
    const max = kind === 'startOtp'
        ? MAX_START_OTP_PER_IP_PER_WINDOW
        : kind === 'confirmOtp'
            ? MAX_CONFIRM_OTP_PER_IP_PER_WINDOW
            : kind === 'phoneProof'
                ? MAX_PHONE_PROOF_PER_IP_PER_WINDOW
                : MAX_DIRECT_DELETE_PER_IP_PER_WINDOW;
    const countField = kind === 'startOtp'
        ? 'startOtpCount'
        : kind === 'confirmOtp'
            ? 'confirmOtpCount'
            : kind === 'phoneProof'
                ? 'phoneProofCount'
                : 'directDeleteCount';
    const windowField = kind === 'startOtp'
        ? 'startOtpWindowAt'
        : kind === 'confirmOtp'
            ? 'confirmOtpWindowAt'
            : kind === 'phoneProof'
                ? 'phoneProofWindowAt'
                : 'directDeleteWindowAt';
    await db.runTransaction(async (tx) => {
        var _a, _b, _c, _d;
        const snap = await tx.get(ref);
        const data = (_a = snap.data()) !== null && _a !== void 0 ? _a : {};
        const now = Date.now();
        let windowStart = (_c = (_b = data[windowField]) === null || _b === void 0 ? void 0 : _b.toMillis()) !== null && _c !== void 0 ? _c : 0;
        let count = (_d = data[countField]) !== null && _d !== void 0 ? _d : 0;
        if (now - windowStart > IP_WINDOW_MS) {
            windowStart = now;
            count = 0;
        }
        count += 1;
        if (count > max) {
            const retryAfterSeconds = Math.max(1, Math.ceil((windowStart + IP_WINDOW_MS - now) / 1000));
            throw new https_1.HttpsError('resource-exhausted', 'Too many requests from this network. Try again later.', { retryAfterSeconds });
        }
        tx.set(ref, {
            [windowField]: admin.firestore.Timestamp.fromMillis(windowStart),
            [countField]: count,
            ipHashShort: ipHashShort(ip),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            expireAt: admin.firestore.Timestamp.fromMillis(now + ABUSE_DOC_TTL_MS),
        }, { merge: true });
    });
}
function scrubClientMeta(raw) {
    if (raw == null || typeof raw !== 'object') {
        return undefined;
    }
    const o = raw;
    const platform = o.platform != null ? String(o.platform).slice(0, 32) : '';
    const appVersion = o.appVersion != null ? String(o.appVersion).slice(0, 32) : '';
    if (!platform && !appVersion) {
        return undefined;
    }
    const out = {};
    if (platform) {
        out.platform = platform;
    }
    if (appVersion) {
        out.appVersion = appVersion;
    }
    return out;
}
/** Exported for unit tests (invoke with mocked `firebase-admin`). */
async function startDeletionOtpHandler(request) {
    var _a, _b, _c, _d, _e;
    const cr = request;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = request.auth.uid;
    const payload = ((_b = request.data) !== null && _b !== void 0 ? _b : {});
    const channelRaw = payload.channel;
    const channel = channelRaw !== null && channelRaw !== void 0 ? channelRaw : 'email';
    if (channel !== 'email') {
        throw new https_1.HttpsError('invalid-argument', 'Use email for this step. Phone accounts verify with a text code in the app, then confirm deletion.');
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
    if (data === null || data === void 0 ? void 0 : data.lockedUntil) {
        const lockedUntil = data.lockedUntil;
        if (lockedUntil.toMillis() > now) {
            const retryAfterSeconds = Math.max(1, Math.ceil((lockedUntil.toMillis() - now) / 1000));
            throw new https_1.HttpsError('resource-exhausted', 'Too many incorrect codes. Try again later.', { retryAfterSeconds });
        }
    }
    if (data === null || data === void 0 ? void 0 : data.lastSentAt) {
        const last = data.lastSentAt.toMillis();
        if (now - last < RESEND_COOLDOWN_MS) {
            const retryAfterSeconds = Math.max(1, Math.ceil((RESEND_COOLDOWN_MS - (now - last)) / 1000));
            throw new https_1.HttpsError('resource-exhausted', 'Please wait before requesting another code.', { retryAfterSeconds });
        }
    }
    if (!user.email) {
        throw new https_1.HttpsError('failed-precondition', 'No email on this account to send a code to.');
    }
    const destination = maskEmail(user.email);
    const code = (0, accountDeletionOtpCrypto_1.generateNumericOtp)();
    const { saltB64, hashB64 } = (0, accountDeletionOtpCrypto_1.hashOtp)(code, pepper);
    const expiresAt = admin.firestore.Timestamp.fromMillis(now + OTP_TTL_MS);
    const nextResend = (_c = data === null || data === void 0 ? void 0 : data.resendCount) !== null && _c !== void 0 ? _c : 0;
    await ref.set({
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
    }, { merge: true });
    try {
        await (0, accountDeletionMessaging_1.sendDeletionOtpEmail)({ to: user.email, code });
        logMetric('account_deletion_otp_sent', { uid, channel: 'email' });
    }
    catch (err) {
        console.error('startDeletionOtp send failed', err);
        logMetric('account_deletion_otp_send_failed', {
            uid,
            channel,
            error: String((_d = err.message) !== null && _d !== void 0 ? _d : err),
        });
        await ref.set({
            sendErrorAt: admin.firestore.FieldValue.serverTimestamp(),
            sendErrorMessage: String((_e = err.message) !== null && _e !== void 0 ? _e : err),
        }, { merge: true });
        throw new https_1.HttpsError('internal', 'Could not send your code. Try again or use another verification method.');
    }
    return {
        ok: true,
        channel,
        destinationHint: destination,
        expiresInSeconds: Math.floor(OTP_TTL_MS / 1000),
    };
}
exports.startDeletionOtp = (0, https_1.onCall)({
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
}, startDeletionOtpHandler);
/** Exported for unit tests (invoke with mocked `firebase-admin`). */
async function confirmDeletionOtpHandler(request) {
    var _a, _b, _c, _d, _e, _f, _g;
    const cr = request;
    if (!((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid)) {
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = request.auth.uid;
    const payload = ((_b = request.data) !== null && _b !== void 0 ? _b : {});
    const code = String((_c = payload.code) !== null && _c !== void 0 ? _c : '').replace(/\D/g, '');
    const reasonRaw = String((_d = payload.reason) !== null && _d !== void 0 ? _d : '').trim();
    const customReason = payload.customReason != null ? String(payload.customReason).trim() : '';
    const clientMeta = scrubClientMeta(payload.clientMeta);
    if (code.length !== 6) {
        throw new https_1.HttpsError('invalid-argument', 'Enter the 6-digit code.');
    }
    if (customReason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Custom reason is too long.');
    }
    const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
    if (reason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Invalid deletion reason.');
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
        throw new https_1.HttpsError('not-found', 'No active verification. Request a new code.');
    }
    const v = snap.data();
    const now = Date.now();
    if (v.channel != null && v.channel !== 'email') {
        throw new https_1.HttpsError('failed-precondition', 'Request a new email code to continue.');
    }
    if (v.consumedAt) {
        throw new https_1.HttpsError('failed-precondition', 'This code was already used. Request a new code.');
    }
    if (v.lockedUntil) {
        const lockedUntil = v.lockedUntil.toMillis();
        if (lockedUntil > now) {
            const retryAfterSeconds = Math.max(1, Math.ceil((lockedUntil - now) / 1000));
            throw new https_1.HttpsError('resource-exhausted', 'Too many incorrect codes. Try again later.', { retryAfterSeconds });
        }
    }
    const expiresAt = v.expiresAt;
    if (expiresAt.toMillis() < now) {
        throw new https_1.HttpsError('failed-precondition', 'Code expired. Request a new one.');
    }
    const ok = (0, accountDeletionOtpCrypto_1.verifyOtp)(code, pepper, v.salt, v.codeHash);
    const prevAttempts = (_e = v.attemptCount) !== null && _e !== void 0 ? _e : 0;
    const attempts = prevAttempts + 1;
    if (!ok) {
        const updates = {
            attemptCount: attempts,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (attempts >= MAX_ATTEMPTS) {
            updates.lockedUntil = admin.firestore.Timestamp.fromMillis(now + LOCKOUT_MS);
        }
        await vRef.set(updates, { merge: true });
        logMetric('account_deletion_otp_confirm_fail', {
            uid,
            reason: 'bad_code',
            attempts,
        });
        const attemptsRemaining = Math.max(0, MAX_ATTEMPTS - attempts);
        if (attempts >= MAX_ATTEMPTS) {
            throw new https_1.HttpsError('resource-exhausted', 'Too many incorrect codes. Try again later.', { retryAfterSeconds: Math.ceil(LOCKOUT_MS / 1000), attemptsRemaining: 0 });
        }
        throw new https_1.HttpsError('permission-denied', 'That code does not match. Check and try again.', { attemptsRemaining });
    }
    await db.runTransaction(async (tx) => {
        var _a, _b, _c;
        const s = await tx.get(vRef);
        if (!s.exists) {
            throw new https_1.HttpsError('not-found', 'No active verification. Request a new code.');
        }
        const fresh = s.data();
        if (fresh.consumedAt) {
            throw new https_1.HttpsError('failed-precondition', 'This code was already used. Request a new code.');
        }
        const stillOk = (0, accountDeletionOtpCrypto_1.verifyOtp)(code, pepper, fresh.salt, fresh.codeHash);
        if (!stillOk) {
            const attemptsRemaining = Math.max(0, MAX_ATTEMPTS - ((_a = fresh.attemptCount) !== null && _a !== void 0 ? _a : 0) - 1);
            throw new https_1.HttpsError('permission-denied', 'That code does not match. Check and try again.', { attemptsRemaining });
        }
        tx.set(vRef, {
            consumedAt: admin.firestore.FieldValue.serverTimestamp(),
            attemptCount: attempts,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        const auditRef = db.collection('accountDeletions').doc(uid);
        tx.set(auditRef, {
            userId: uid,
            email: (_b = user.email) !== null && _b !== void 0 ? _b : null,
            phoneNumber: (_c = user.phoneNumber) !== null && _c !== void 0 ? _c : null,
            authProvider,
            reason,
            customReason: customReason.length > 0 ? customReason : null,
            requestedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'pending',
            otpVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            otpChannel: 'email',
            otpConfirmAttempts: attempts,
        }, { merge: true });
    });
    try {
        await auth.deleteUser(uid);
        logMetric('account_deletion_confirm_ok', { uid, method: 'email_otp' });
    }
    catch (err) {
        console.error('confirmDeletionOtp deleteUser failed', err);
        logMetric('account_deletion_auth_delete_failed', {
            uid,
            error: String((_f = err.message) !== null && _f !== void 0 ? _f : err),
        });
        const auditRef = db.collection('accountDeletions').doc(uid);
        await auditRef.set({
            status: 'failed',
            failureStage: 'auth_delete',
            failureMessage: String((_g = err.message) !== null && _g !== void 0 ? _g : err),
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        throw new https_1.HttpsError('internal', 'Could not complete account deletion. Please contact support.');
    }
    return { ok: true };
}
exports.confirmDeletionOtp = (0, https_1.onCall)({
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
}, confirmDeletionOtpHandler);
/**
 * After client phone re-verification, verifies a fresh ID token
 * (phone provider + recent auth_time) and deletes the user.
 */
async function confirmDeletionAfterPhoneProofHandler(request) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const cr = request;
    const payload = ((_a = request.data) !== null && _a !== void 0 ? _a : {});
    const idToken = String((_b = payload.idToken) !== null && _b !== void 0 ? _b : '').trim();
    const reasonRaw = String((_c = payload.reason) !== null && _c !== void 0 ? _c : '').trim();
    const customReason = payload.customReason != null ? String(payload.customReason).trim() : '';
    const clientMeta = scrubClientMeta(payload.clientMeta);
    if (!idToken) {
        throw new https_1.HttpsError('invalid-argument', 'Missing session proof.');
    }
    if (customReason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Custom reason is too long.');
    }
    const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
    if (reason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Invalid deletion reason.');
    }
    const auth = admin.auth();
    let decoded;
    try {
        decoded = await auth.verifyIdToken(idToken, true);
    }
    catch (_j) {
        throw new https_1.HttpsError('permission-denied', 'Invalid or expired session. Verify your phone again.');
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
    const signInProvider = (_d = decoded.firebase) === null || _d === void 0 ? void 0 : _d.sign_in_provider;
    if (signInProvider !== 'phone') {
        throw new https_1.HttpsError('failed-precondition', 'Recent phone verification required. Finish the text code step in the app.');
    }
    const nowSec = Math.floor(Date.now() / 1000);
    if (nowSec - decoded.auth_time > PHONE_PROOF_MAX_AGE_SEC) {
        throw new https_1.HttpsError('failed-precondition', 'Verification expired. Request a new code and try again.');
    }
    const user = await auth.getUser(uid);
    if (!user.phoneNumber) {
        throw new https_1.HttpsError('failed-precondition', 'No phone number on this account.');
    }
    const authProvider = inferAuthProvider(user);
    const auditRef = db.collection('accountDeletions').doc(uid);
    await auditRef.set({
        userId: uid,
        email: (_e = user.email) !== null && _e !== void 0 ? _e : null,
        phoneNumber: (_f = user.phoneNumber) !== null && _f !== void 0 ? _f : null,
        authProvider,
        reason,
        customReason: customReason.length > 0 ? customReason : null,
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        verificationMethod: 'firebase_phone',
        phoneProofVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    try {
        await auth.deleteUser(uid);
        logMetric('account_deletion_confirm_ok', { uid, method: 'phone_proof' });
    }
    catch (err) {
        console.error('confirmDeletionAfterPhoneProof deleteUser failed', err);
        logMetric('account_deletion_auth_delete_failed', {
            uid,
            method: 'phone_proof',
            error: String((_g = err.message) !== null && _g !== void 0 ? _g : err),
        });
        await auditRef.set({
            status: 'failed',
            failureStage: 'auth_delete',
            failureMessage: String((_h = err.message) !== null && _h !== void 0 ? _h : err),
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        throw new https_1.HttpsError('internal', 'Could not complete account deletion. Please contact support.');
    }
    return { ok: true };
}
exports.confirmDeletionAfterPhoneProof = (0, https_1.onCall)({
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
}, confirmDeletionAfterPhoneProofHandler);
/**
 * Direct account deletion for signed-in users (no OTP challenge).
 * Verifies ID token and deletes immediately.
 */
async function deleteAccountDirectHandler(request) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const cr = request;
    const payload = ((_a = request.data) !== null && _a !== void 0 ? _a : {});
    const idToken = String((_b = payload.idToken) !== null && _b !== void 0 ? _b : '').trim();
    const reasonRaw = String((_c = payload.reason) !== null && _c !== void 0 ? _c : '').trim();
    const customReason = payload.customReason != null ? String(payload.customReason).trim() : '';
    const clientMeta = scrubClientMeta(payload.clientMeta);
    if (!idToken) {
        throw new https_1.HttpsError('invalid-argument', 'Missing session proof.');
    }
    if (customReason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Custom reason is too long.');
    }
    const reason = reasonRaw.length > 0 ? reasonRaw : 'Not specified';
    if (reason.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Invalid deletion reason.');
    }
    const auth = admin.auth();
    let decoded;
    try {
        decoded = await auth.verifyIdToken(idToken, true);
    }
    catch (_k) {
        throw new https_1.HttpsError('permission-denied', 'Invalid or expired session. Please sign in again.');
    }
    const uid = decoded.uid;
    if (((_d = request.auth) === null || _d === void 0 ? void 0 : _d.uid) && request.auth.uid !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Session does not match the signed-in account.');
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
        callableAuthPresent: ((_e = request.auth) === null || _e === void 0 ? void 0 : _e.uid) != null,
        clientMeta,
    });
    const user = await auth.getUser(uid);
    const authProvider = inferAuthProvider(user);
    const auditRef = db.collection('accountDeletions').doc(uid);
    await auditRef.set({
        userId: uid,
        email: (_f = user.email) !== null && _f !== void 0 ? _f : null,
        phoneNumber: (_g = user.phoneNumber) !== null && _g !== void 0 ? _g : null,
        authProvider,
        reason,
        customReason: customReason.length > 0 ? customReason : null,
        requestedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
        verificationMethod: 'active_session',
        sessionVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    try {
        await auth.deleteUser(uid);
        logMetric('account_deletion_confirm_ok', { uid, method: 'direct' });
    }
    catch (err) {
        console.error('deleteAccountDirect deleteUser failed', err);
        logMetric('account_deletion_auth_delete_failed', {
            uid,
            method: 'direct',
            error: String((_h = err.message) !== null && _h !== void 0 ? _h : err),
        });
        await auditRef.set({
            status: 'failed',
            failureStage: 'auth_delete',
            failureMessage: String((_j = err.message) !== null && _j !== void 0 ? _j : err),
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        throw new https_1.HttpsError('internal', 'Could not complete account deletion. Please contact support.');
    }
    return { ok: true };
}
exports.deleteAccountDirect = (0, https_1.onCall)({
    region: REGION,
    enforceAppCheck: ENFORCE_APPCHECK,
}, deleteAccountDirectHandler);
function maskEmail(email) {
    const [a, domain] = email.split('@');
    if (!domain)
        return '***';
    const head = a.slice(0, 2);
    return `${head}***@${domain}`;
}
//# sourceMappingURL=accountDeletionCallables.js.map