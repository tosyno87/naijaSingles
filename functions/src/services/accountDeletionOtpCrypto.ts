/**
 * OTP generation and scrypt-based hashing (pepper from env).
 */

import {randomInt, randomBytes, scryptSync, timingSafeEqual} from 'crypto';

const OTP_LENGTH = 6;
const SCRYPT_KEY_LEN = 32;

export function generateNumericOtp(): string {
  const n = randomInt(0, 1_000_000);
  return n.toString().padStart(OTP_LENGTH, '0');
}

export function hashOtp(
  code: string,
  pepper: string
): {saltB64: string; hashB64: string} {
  const salt = randomBytes(16);
  const hash = scryptSync(`${code}${pepper}`, salt, SCRYPT_KEY_LEN);
  return {
    saltB64: salt.toString('base64'),
    hashB64: hash.toString('base64'),
  };
}

export function verifyOtp(
  code: string,
  pepper: string,
  saltB64: string,
  hashB64: string
): boolean {
  try {
    const salt = Buffer.from(saltB64, 'base64');
    const expected = Buffer.from(hashB64, 'base64');
    const actual = scryptSync(`${code}${pepper}`, salt, SCRYPT_KEY_LEN);
    if (actual.length !== expected.length) return false;
    return timingSafeEqual(actual, expected);
  } catch {
    return false;
  }
}
