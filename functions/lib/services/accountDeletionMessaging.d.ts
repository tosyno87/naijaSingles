/**
 * Send deletion OTP via SendGrid (email) or Twilio (SMS). Uses native https — no extra deps.
 */
export declare function sendDeletionOtpEmail(params: {
    to: string;
    code: string;
    appName?: string;
}): Promise<void>;
export declare function isTwilioConfigured(): boolean;
export declare function sendDeletionOtpSms(params: {
    toE164: string;
    code: string;
    appName?: string;
}): Promise<void>;
//# sourceMappingURL=accountDeletionMessaging.d.ts.map