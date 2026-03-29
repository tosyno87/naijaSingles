import {
  generateNumericOtp,
  hashOtp,
  verifyOtp,
} from '../accountDeletionOtpCrypto';

describe('accountDeletionOtpCrypto', () => {
  const pepper = 'test-pepper-at-least-16-chars';

  it('generateNumericOtp returns 6 digits', () => {
    const o = generateNumericOtp();
    expect(o).toMatch(/^\d{6}$/);
  });

  it('verifyOtp succeeds for matching code', () => {
    const code = '123456';
    const {saltB64, hashB64} = hashOtp(code, pepper);
    expect(verifyOtp(code, pepper, saltB64, hashB64)).toBe(true);
  });

  it('verifyOtp fails for wrong code', () => {
    const {saltB64, hashB64} = hashOtp('111111', pepper);
    expect(verifyOtp('222222', pepper, saltB64, hashB64)).toBe(false);
  });

  it('verifyOtp fails for tampered hash', () => {
    const {saltB64, hashB64} = hashOtp('333333', pepper);
    const bad = Buffer.from(hashB64, 'base64');
    bad[0] ^= 0xff;
    expect(verifyOtp('333333', pepper, saltB64, bad.toString('base64'))).toBe(
      false
    );
  });
});
