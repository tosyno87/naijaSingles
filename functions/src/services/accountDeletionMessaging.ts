/**
 * Send deletion OTP via SendGrid (email) or Twilio (SMS). Uses native https — no extra deps.
 */

import * as https from 'https';

function postJson(
  host: string,
  path: string,
  headers: Record<string, string>,
  body: unknown
): Promise<{status: number; body: string}> {
  const payload = JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: host,
        path,
        method: 'POST',
        headers: {
          ...headers,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (res) => {
        const chunks: Buffer[] = [];
        res.on('data', (c) => chunks.push(c as Buffer));
        res.on('end', () => {
          resolve({
            status: res.statusCode ?? 0,
            body: Buffer.concat(chunks).toString('utf8'),
          });
        });
      }
    );
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

function postForm(
  host: string,
  path: string,
  authHeader: string,
  formBody: string
): Promise<{status: number; body: string}> {
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: host,
        path,
        method: 'POST',
        headers: {
          Authorization: `Basic ${authHeader}`,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': Buffer.byteLength(formBody),
        },
      },
      (res) => {
        const chunks: Buffer[] = [];
        res.on('data', (c) => chunks.push(c as Buffer));
        res.on('end', () => {
          resolve({
            status: res.statusCode ?? 0,
            body: Buffer.concat(chunks).toString('utf8'),
          });
        });
      }
    );
    req.on('error', reject);
    req.write(formBody);
    req.end();
  });
}

export async function sendDeletionOtpEmail(params: {
  to: string;
  code: string;
  appName?: string;
}): Promise<void> {
  const apiKey = process.env.SENDGRID_API_KEY?.trim();
  if (!apiKey) {
    console.warn(
      'SENDGRID_API_KEY not set; skipping deletion OTP email (dev only)'
    );
    return;
  }
  const appName = params.appName ?? 'Afropeep';
  const body = {
    personalizations: [{to: [{email: params.to}]}],
    from: {
      email:
        process.env.SENDGRID_FROM_EMAIL?.trim() || 'noreply@naijasingles.com',
      name: appName,
    },
    subject: `${appName}: Your account deletion code`,
    content: [
      {
        type: 'text/plain',
        value: `Your verification code is: ${params.code}\n\nIf you did not request account deletion, ignore this email and secure your account.`,
      },
    ],
  };
  const res = await postJson(
    'api.sendgrid.com',
    '/v3/mail/send',
    {Authorization: `Bearer ${apiKey}`},
    body
  );
  if (res.status < 200 || res.status >= 300) {
    throw new Error(`SendGrid error ${res.status}: ${res.body}`);
  }
}

export function isTwilioConfigured(): boolean {
  return Boolean(
    process.env.TWILIO_ACCOUNT_SID?.trim() &&
      process.env.TWILIO_AUTH_TOKEN?.trim() &&
      process.env.TWILIO_FROM_NUMBER?.trim()
  );
}

export async function sendDeletionOtpSms(params: {
  toE164: string;
  code: string;
  appName?: string;
}): Promise<void> {
  const sid = process.env.TWILIO_ACCOUNT_SID?.trim();
  const token = process.env.TWILIO_AUTH_TOKEN?.trim();
  const from = process.env.TWILIO_FROM_NUMBER?.trim();
  if (!sid || !token || !from) {
    throw new Error('Twilio is not configured for SMS OTP');
  }
  const appName = params.appName ?? 'Afropeep';
  const authHeader = Buffer.from(`${sid}:${token}`).toString('base64');
  const formBody = new URLSearchParams({
    To: params.toE164,
    From: from,
    Body: `${appName} deletion code: ${params.code}`,
  }).toString();
  const res = await postForm(
    'api.twilio.com',
    `/2010-04-01/Accounts/${sid}/Messages.json`,
    authHeader,
    formBody
  );
  if (res.status < 200 || res.status >= 300) {
    throw new Error(`Twilio error ${res.status}: ${res.body}`);
  }
}
