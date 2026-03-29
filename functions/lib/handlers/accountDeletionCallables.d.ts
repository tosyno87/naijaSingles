/**
 * Callable HTTPS: start / confirm account deletion OTP, then Admin deleteUser.
 */
import { CallableRequest } from 'firebase-functions/v2/https';
/** Exported for unit tests (Express-style rawRequest shapes). */
export declare function extractClientIp(request: CallableRequest): string | null;
export type AccountDeletionCallableRequest = {
    auth?: {
        uid: string;
    } | null;
    data?: unknown;
    rawRequest?: CallableRequest['rawRequest'];
    app?: CallableRequest['app'];
};
/** Exported for unit tests (invoke with mocked `firebase-admin`). */
export declare function startDeletionOtpHandler(request: AccountDeletionCallableRequest): Promise<Record<string, unknown>>;
export declare const startDeletionOtp: import("firebase-functions/v2/https").CallableFunction<unknown, Promise<Record<string, unknown>>, unknown>;
/** Exported for unit tests (invoke with mocked `firebase-admin`). */
export declare function confirmDeletionOtpHandler(request: AccountDeletionCallableRequest): Promise<Record<string, unknown>>;
export declare const confirmDeletionOtp: import("firebase-functions/v2/https").CallableFunction<unknown, Promise<Record<string, unknown>>, unknown>;
/**
 * After client phone re-verification, verifies a fresh ID token
 * (phone provider + recent auth_time) and deletes the user.
 */
export declare function confirmDeletionAfterPhoneProofHandler(request: AccountDeletionCallableRequest): Promise<Record<string, unknown>>;
export declare const confirmDeletionAfterPhoneProof: import("firebase-functions/v2/https").CallableFunction<unknown, Promise<Record<string, unknown>>, unknown>;
/**
 * Direct account deletion for signed-in users (no OTP challenge).
 * Verifies ID token and deletes immediately.
 */
export declare function deleteAccountDirectHandler(request: AccountDeletionCallableRequest): Promise<Record<string, unknown>>;
export declare const deleteAccountDirect: import("firebase-functions/v2/https").CallableFunction<unknown, Promise<Record<string, unknown>>, unknown>;
//# sourceMappingURL=accountDeletionCallables.d.ts.map