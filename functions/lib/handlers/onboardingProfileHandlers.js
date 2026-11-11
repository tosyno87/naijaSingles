"use strict";
/**
 * Authenticated callable: transcribe prompted answers and extract a draft profile.
 * Audio is processed in memory and discarded. Rate-limited to 1 extract / uid / 24h.
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
exports.extractOnboardingProfile = void 0;
exports.createOpenAiClient = createOpenAiClient;
exports.extractOnboardingProfileHandler = extractOnboardingProfileHandler;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const onboardingProfileExtraction_1 = require("../services/onboardingProfileExtraction");
const REGION = 'us-central1';
const EXTRACTIONS = 'onboardingExtractions';
const RUNTIME_CONFIG = 'runtimeConfig';
const BUDGET_DOC = 'onboardingAi';
const openaiApiKey = (0, params_1.defineSecret)('OPENAI_API_KEY');
/** When false, App Check is not enforced (dev/staging only). */
const ENFORCE_APPCHECK = (process.env.ONBOARDING_AI_ENFORCE_APPCHECK ?? 'true').toLowerCase() !==
    'false';
console.log(JSON.stringify({
    event: 'onboarding_extract_callable_config',
    enforceAppCheck: ENFORCE_APPCHECK,
    ts: new Date().toISOString(),
}));
function toHttpsError(error) {
    if (error instanceof https_1.HttpsError) {
        return error;
    }
    if (error instanceof onboardingProfileExtraction_1.ExtractionValidationError) {
        return new https_1.HttpsError(error.code, error.message);
    }
    console.error(JSON.stringify({
        event: 'onboarding_extract_unhandled',
        err: String(error),
    }));
    return new https_1.HttpsError('internal', 'Could not draft your profile');
}
function extensionForMime(mimeType) {
    if (mimeType.includes('wav')) {
        return 'wav';
    }
    if (mimeType.includes('mpeg') || mimeType.includes('mp3')) {
        return 'mp3';
    }
    if (mimeType.includes('webm')) {
        return 'webm';
    }
    return 'm4a';
}
function createOpenAiClient(apiKey) {
    const transcribeModel = process.env.OPENAI_TRANSCRIBE_MODEL ?? 'gpt-4o-mini-transcribe';
    const extractModel = process.env.OPENAI_EXTRACT_MODEL ?? 'gpt-4o-mini';
    return {
        async transcribe(audio, mimeType) {
            const form = new FormData();
            const blob = new Blob([new Uint8Array(audio)], { type: mimeType });
            form.append('file', blob, `answer.${extensionForMime(mimeType)}`);
            form.append('model', transcribeModel);
            const res = await fetch('https://api.openai.com/v1/audio/transcriptions', {
                method: 'POST',
                headers: { Authorization: `Bearer ${apiKey}` },
                body: form,
            });
            if (!res.ok) {
                const body = await res.text();
                console.error(JSON.stringify({
                    event: 'onboarding_transcribe_error',
                    status: res.status,
                    body: body.slice(0, 300),
                }));
                throw new onboardingProfileExtraction_1.ExtractionValidationError('failed-precondition', 'ai_unavailable');
            }
            const json = (await res.json());
            return (json.text ?? '').trim();
        },
        async extract(transcript) {
            const res = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    Authorization: `Bearer ${apiKey}`,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    model: extractModel,
                    response_format: { type: 'json_object' },
                    temperature: 0,
                    messages: [
                        { role: 'system', content: onboardingProfileExtraction_1.EXTRACTION_SYSTEM_PROMPT },
                        { role: 'user', content: transcript },
                    ],
                }),
            });
            if (!res.ok) {
                const body = await res.text();
                console.error(JSON.stringify({
                    event: 'onboarding_extract_error',
                    status: res.status,
                    body: body.slice(0, 300),
                }));
                throw new onboardingProfileExtraction_1.ExtractionValidationError('failed-precondition', 'ai_unavailable');
            }
            const json = (await res.json());
            const content = json.choices?.[0]?.message?.content ?? '';
            const parsed = (0, onboardingProfileExtraction_1.parseExtractionJson)(content);
            return (0, onboardingProfileExtraction_1.sanitizeExtractedProfile)(parsed.fields, parsed.confidence, new Date());
        },
    };
}
async function transcribeAnswers(answers, client) {
    const out = [];
    for (const answer of answers) {
        let text = answer.text;
        if (answer.audio) {
            const spoken = await client.transcribe(answer.audio.buffer, answer.audio.mimeType);
            text = [text, spoken].filter((part) => part.length > 0).join('\n');
        }
        out.push({ promptId: answer.promptId, text });
    }
    return out;
}
async function extractOnboardingProfileHandler(request, deps) {
    if (!request.auth?.uid) {
        throw new https_1.HttpsError('unauthenticated', 'Sign in required');
    }
    const uid = request.auth.uid;
    const now = deps.now();
    const nowMs = now.getTime();
    try {
        const answers = (0, onboardingProfileExtraction_1.validateAnswers)(request.data?.answers);
        if ((0, onboardingProfileExtraction_1.isReviewFixtureUid)(uid, deps.reviewUids)) {
            return {
                fields: onboardingProfileExtraction_1.REVIEW_FIXTURE.fields,
                confidence: onboardingProfileExtraction_1.REVIEW_FIXTURE.confidence,
                source: onboardingProfileExtraction_1.REVIEW_FIXTURE.source,
            };
        }
        // Only users still in onboarding may invoke the paid extract path.
        // Review fixture UIDs are exempted above.
        const userSnap = await deps.db.collection('users').doc(uid).get();
        const userData = userSnap.data() ?? {};
        if (userData.onboardingCompleted === true) {
            throw new onboardingProfileExtraction_1.ExtractionValidationError('failed-precondition', 'onboarding already completed');
        }
        const key = deps.openaiKey ?? process.env.OPENAI_API_KEY ?? '';
        const client = deps.openai ?? (key ? createOpenAiClient(key) : undefined);
        if (!client) {
            throw new onboardingProfileExtraction_1.ExtractionValidationError('failed-precondition', 'ai_unavailable');
        }
        const parsedCap = Number.parseInt(process.env.ONBOARDING_AI_DAILY_CAP_CENTS ?? '', 10);
        const cap = deps.dailyCapCents ??
            (Number.isFinite(parsedCap) ? parsedCap : onboardingProfileExtraction_1.DEFAULT_DAILY_CAP_CENTS);
        const extractionRef = deps.db.collection(EXTRACTIONS).doc(uid);
        const budgetRef = deps.db.collection(RUNTIME_CONFIG).doc(BUDGET_DOC);
        // Stamp the per-uid cooldown and reserve org spend *before* OpenAI work
        // so a failed transcription/extract cannot be retried into a budget drain.
        await deps.db.runTransaction(async (tx) => {
            const priorSnap = await tx.get(extractionRef);
            const prior = priorSnap.data() ?? {};
            const lastAttemptMs = typeof prior.lastAttemptAtMs === 'number'
                ? prior.lastAttemptAtMs
                : typeof prior.lastExtractedAtMs === 'number'
                    ? prior.lastExtractedAtMs
                    : null;
            (0, onboardingProfileExtraction_1.assertRateLimit)(lastAttemptMs, nowMs);
            const budgetSnap = await tx.get(budgetRef);
            const budget = budgetSnap.data() ?? {};
            const next = (0, onboardingProfileExtraction_1.nextBudgetState)({
                storedDayKey: typeof budget.dayKey === 'string' ? budget.dayKey : undefined,
                storedSpentCents: typeof budget.spentCents === 'number' ? budget.spentCents : undefined,
                dailyCapCents: cap,
                now,
                addCents: onboardingProfileExtraction_1.COST_CENTS_PER_EXTRACT,
            });
            tx.set(extractionRef, {
                lastAttemptAtMs: nowMs,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            tx.set(budgetRef, {
                dayKey: next.dayKey,
                spentCents: next.spentCents,
                dailyCapCents: cap,
                updatedAtMs: nowMs,
            }, { merge: true });
        });
        const transcribed = await transcribeAnswers(answers, client);
        const transcript = (0, onboardingProfileExtraction_1.combineTranscript)(transcribed);
        if (!transcript) {
            throw new onboardingProfileExtraction_1.ExtractionValidationError('invalid-argument', 'no speech or text to extract');
        }
        const extracted = await client.extract(transcript);
        const profile = extracted.source === 'review_fixture'
            ? extracted
            : (0, onboardingProfileExtraction_1.sanitizeExtractedProfile)(extracted.fields, extracted.confidence, now);
        await extractionRef.set({
            lastExtractedAtMs: nowMs,
            lastAttemptAtMs: nowMs,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            fields: profile.fields,
            confidence: profile.confidence,
            source: profile.source,
        };
    }
    catch (error) {
        throw toHttpsError(error);
    }
}
exports.extractOnboardingProfile = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 120,
    memory: '512MiB',
    secrets: [openaiApiKey],
    enforceAppCheck: ENFORCE_APPCHECK,
}, async (request) => extractOnboardingProfileHandler(request, {
    db: admin.firestore(),
    now: () => new Date(),
    openaiKey: openaiApiKey.value(),
    reviewUids: process.env.ONBOARDING_AI_REVIEW_UIDS,
}));
//# sourceMappingURL=onboardingProfileHandlers.js.map