"use strict";
/**
 * OTP generation and scrypt-based hashing (pepper from env).
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateNumericOtp = generateNumericOtp;
exports.hashOtp = hashOtp;
exports.verifyOtp = verifyOtp;
const crypto_1 = require("crypto");
const OTP_LENGTH = 6;
const SCRYPT_KEY_LEN = 32;
function generateNumericOtp() {
    const n = (0, crypto_1.randomInt)(0, 1_000_000);
    return n.toString().padStart(OTP_LENGTH, '0');
}
function hashOtp(code, pepper) {
    const salt = (0, crypto_1.randomBytes)(16);
    const hash = (0, crypto_1.scryptSync)(`${code}${pepper}`, salt, SCRYPT_KEY_LEN);
    return {
        saltB64: salt.toString('base64'),
        hashB64: hash.toString('base64'),
    };
}
function verifyOtp(code, pepper, saltB64, hashB64) {
    try {
        const salt = Buffer.from(saltB64, 'base64');
        const expected = Buffer.from(hashB64, 'base64');
        const actual = (0, crypto_1.scryptSync)(`${code}${pepper}`, salt, SCRYPT_KEY_LEN);
        if (actual.length !== expected.length)
            return false;
        return (0, crypto_1.timingSafeEqual)(actual, expected);
    }
    catch {
        return false;
    }
}
//# sourceMappingURL=accountDeletionOtpCrypto.js.map