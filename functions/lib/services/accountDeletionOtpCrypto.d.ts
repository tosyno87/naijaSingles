/**
 * OTP generation and scrypt-based hashing (pepper from env).
 */
export declare function generateNumericOtp(): string;
export declare function hashOtp(code: string, pepper: string): {
    saltB64: string;
    hashB64: string;
};
export declare function verifyOtp(code: string, pepper: string, saltB64: string, hashB64: string): boolean;
//# sourceMappingURL=accountDeletionOtpCrypto.d.ts.map