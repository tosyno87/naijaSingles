"use strict";
/**
 * Send deletion OTP via SendGrid (email) or Twilio (SMS). Uses native https — no extra deps.
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendDeletionOtpEmail = sendDeletionOtpEmail;
exports.isTwilioConfigured = isTwilioConfigured;
exports.sendDeletionOtpSms = sendDeletionOtpSms;
const https = __importStar(require("https"));
function postJson(host, path, headers, body) {
    const payload = JSON.stringify(body);
    return new Promise((resolve, reject) => {
        const req = https.request({
            hostname: host,
            path,
            method: 'POST',
            headers: {
                ...headers,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(payload),
            },
        }, (res) => {
            const chunks = [];
            res.on('data', (c) => chunks.push(c));
            res.on('end', () => {
                resolve({
                    status: res.statusCode ?? 0,
                    body: Buffer.concat(chunks).toString('utf8'),
                });
            });
        });
        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}
function postForm(host, path, authHeader, formBody) {
    return new Promise((resolve, reject) => {
        const req = https.request({
            hostname: host,
            path,
            method: 'POST',
            headers: {
                Authorization: `Basic ${authHeader}`,
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(formBody),
            },
        }, (res) => {
            const chunks = [];
            res.on('data', (c) => chunks.push(c));
            res.on('end', () => {
                resolve({
                    status: res.statusCode ?? 0,
                    body: Buffer.concat(chunks).toString('utf8'),
                });
            });
        });
        req.on('error', reject);
        req.write(formBody);
        req.end();
    });
}
async function sendDeletionOtpEmail(params) {
    const apiKey = process.env.SENDGRID_API_KEY?.trim();
    if (!apiKey) {
        console.warn('SENDGRID_API_KEY not set; skipping deletion OTP email (dev only)');
        return;
    }
    const appName = params.appName ?? 'Afropeep';
    const body = {
        personalizations: [{ to: [{ email: params.to }] }],
        from: {
            email: process.env.SENDGRID_FROM_EMAIL?.trim() || 'noreply@naijasingles.com',
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
    const res = await postJson('api.sendgrid.com', '/v3/mail/send', { Authorization: `Bearer ${apiKey}` }, body);
    if (res.status < 200 || res.status >= 300) {
        throw new Error(`SendGrid error ${res.status}: ${res.body}`);
    }
}
function isTwilioConfigured() {
    return Boolean(process.env.TWILIO_ACCOUNT_SID?.trim() &&
        process.env.TWILIO_AUTH_TOKEN?.trim() &&
        process.env.TWILIO_FROM_NUMBER?.trim());
}
async function sendDeletionOtpSms(params) {
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
    const res = await postForm('api.twilio.com', `/2010-04-01/Accounts/${sid}/Messages.json`, authHeader, formBody);
    if (res.status < 200 || res.status >= 300) {
        throw new Error(`Twilio error ${res.status}: ${res.body}`);
    }
}
//# sourceMappingURL=accountDeletionMessaging.js.map