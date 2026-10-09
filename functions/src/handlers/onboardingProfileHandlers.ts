/**
 * Authenticated callable: transcribe prompted answers and extract a draft profile.
 * Audio is processed in memory and discarded. Rate-limited to 1 extract / uid / 24h.
 */

import * as admin from 'firebase-admin';
import {onCall, HttpsError, CallableRequest} from 'firebase-functions/v2/https';
import {defineSecret} from 'firebase-functions/params';

import {
  COST_CENTS_PER_EXTRACT,
  DEFAULT_DAILY_CAP_CENTS,
  EXTRACTION_SYSTEM_PROMPT,
  ExtractionValidationError,
  ExtractedProfile,
  REVIEW_FIXTURE,
  ValidatedAnswer,
  assertRateLimit,
  combineTranscript,
  isReviewFixtureUid,
  nextBudgetState,
  parseExtractionJson,
  sanitizeExtractedProfile,
  validateAnswers,
} from '../services/onboardingProfileExtraction';

const REGION = 'us-central1';
const EXTRACTIONS = 'onboardingExtractions';
const RUNTIME_CONFIG = 'runtimeConfig';
const BUDGET_DOC = 'onboardingAi';
const openaiApiKey = defineSecret('OPENAI_API_KEY');

/** When false, App Check is not enforced (dev/staging only). */
const ENFORCE_APPCHECK =
  (process.env.ONBOARDING_AI_ENFORCE_APPCHECK ?? 'true').toLowerCase() !==
  'false';

console.log(
  JSON.stringify({
    event: 'onboarding_extract_callable_config',
    enforceAppCheck: ENFORCE_APPCHECK,
    ts: new Date().toISOString(),
  })
);

export type OpenAiClient = {
  transcribe: (audio: Buffer, mimeType: string) => Promise<string>;
  extract: (transcript: string) => Promise<ExtractedProfile>;
};

export type ExtractOnboardingDeps = {
  db: FirebaseFirestore.Firestore;
  now: () => Date;
  openai?: OpenAiClient;
  openaiKey?: string;
  reviewUids?: string;
  dailyCapCents?: number;
};

function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) {
    return error;
  }
  if (error instanceof ExtractionValidationError) {
    return new HttpsError(error.code, error.message);
  }
  console.error(
    JSON.stringify({
      event: 'onboarding_extract_unhandled',
      err: String(error),
    })
  );
  return new HttpsError('internal', 'Could not draft your profile');
}

function extensionForMime(mimeType: string): string {
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

export function createOpenAiClient(apiKey: string): OpenAiClient {
  const transcribeModel =
    process.env.OPENAI_TRANSCRIBE_MODEL ?? 'gpt-4o-mini-transcribe';
  const extractModel = process.env.OPENAI_EXTRACT_MODEL ?? 'gpt-4o-mini';

  return {
    async transcribe(audio: Buffer, mimeType: string): Promise<string> {
      const form = new FormData();
      const blob = new Blob([new Uint8Array(audio)], {type: mimeType});
      form.append('file', blob, `answer.${extensionForMime(mimeType)}`);
      form.append('model', transcribeModel);
      const res = await fetch('https://api.openai.com/v1/audio/transcriptions', {
        method: 'POST',
        headers: {Authorization: `Bearer ${apiKey}`},
        body: form,
      });
      if (!res.ok) {
        const body = await res.text();
        console.error(
          JSON.stringify({
            event: 'onboarding_transcribe_error',
            status: res.status,
            body: body.slice(0, 300),
          })
        );
        throw new ExtractionValidationError(
          'failed-precondition',
          'ai_unavailable'
        );
      }
      const json = (await res.json()) as {text?: string};
      return (json.text ?? '').trim();
    },

    async extract(transcript: string): Promise<ExtractedProfile> {
      const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: extractModel,
          response_format: {type: 'json_object'},
          temperature: 0,
          messages: [
            {role: 'system', content: EXTRACTION_SYSTEM_PROMPT},
            {role: 'user', content: transcript},
          ],
        }),
      });
      if (!res.ok) {
        const body = await res.text();
        console.error(
          JSON.stringify({
            event: 'onboarding_extract_error',
            status: res.status,
            body: body.slice(0, 300),
          })
        );
        throw new ExtractionValidationError(
          'failed-precondition',
          'ai_unavailable'
        );
      }
      const json = (await res.json()) as {
        choices?: Array<{message?: {content?: string}}>;
      };
      const content = json.choices?.[0]?.message?.content ?? '';
      const parsed = parseExtractionJson(content);
      return sanitizeExtractedProfile(parsed.fields, parsed.confidence, new Date());
    },
  };
}

async function transcribeAnswers(
  answers: ValidatedAnswer[],
  client: OpenAiClient
): Promise<Array<{promptId: string; text: string}>> {
  const out: Array<{promptId: string; text: string}> = [];
  for (const answer of answers) {
    let text = answer.text;
    if (answer.audio) {
      const spoken = await client.transcribe(
        answer.audio.buffer,
        answer.audio.mimeType
      );
      text = [text, spoken].filter((part) => part.length > 0).join('\n');
    }
    out.push({promptId: answer.promptId, text});
  }
  return out;
}

export async function extractOnboardingProfileHandler(
  request: CallableRequest<{answers?: unknown}>,
  deps: ExtractOnboardingDeps
): Promise<{fields: Record<string, unknown>; confidence: Record<string, number>; source: string}> {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required');
  }
  const uid = request.auth.uid;
  const now = deps.now();
  const nowMs = now.getTime();

  try {
    const answers = validateAnswers(request.data?.answers);

    if (isReviewFixtureUid(uid, deps.reviewUids)) {
      return {
        fields: REVIEW_FIXTURE.fields,
        confidence: REVIEW_FIXTURE.confidence,
        source: REVIEW_FIXTURE.source,
      };
    }

    const key = deps.openaiKey ?? process.env.OPENAI_API_KEY ?? '';
    const client = deps.openai ?? (key ? createOpenAiClient(key) : undefined);
    if (!client) {
      throw new ExtractionValidationError(
        'failed-precondition',
        'ai_unavailable'
      );
    }

    const parsedCap = Number.parseInt(
      process.env.ONBOARDING_AI_DAILY_CAP_CENTS ?? '',
      10
    );
    const cap =
      deps.dailyCapCents ??
      (Number.isFinite(parsedCap) ? parsedCap : DEFAULT_DAILY_CAP_CENTS);

    const extractionRef = deps.db.collection(EXTRACTIONS).doc(uid);
    const budgetRef = deps.db.collection(RUNTIME_CONFIG).doc(BUDGET_DOC);

    // Stamp the per-uid cooldown and reserve org spend *before* OpenAI work
    // so a failed transcription/extract cannot be retried into a budget drain.
    await deps.db.runTransaction(async (tx) => {
      const priorSnap = await tx.get(extractionRef);
      const prior = priorSnap.data() ?? {};
      const lastAttemptMs =
        typeof prior.lastAttemptAtMs === 'number'
          ? (prior.lastAttemptAtMs as number)
          : typeof prior.lastExtractedAtMs === 'number'
            ? (prior.lastExtractedAtMs as number)
            : null;
      assertRateLimit(lastAttemptMs, nowMs);

      const budgetSnap = await tx.get(budgetRef);
      const budget = budgetSnap.data() ?? {};
      const next = nextBudgetState({
        storedDayKey: typeof budget.dayKey === 'string' ? budget.dayKey : undefined,
        storedSpentCents:
          typeof budget.spentCents === 'number' ? budget.spentCents : undefined,
        dailyCapCents: cap,
        now,
        addCents: COST_CENTS_PER_EXTRACT,
      });
      tx.set(
        extractionRef,
        {
          lastAttemptAtMs: nowMs,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
      tx.set(
        budgetRef,
        {
          dayKey: next.dayKey,
          spentCents: next.spentCents,
          dailyCapCents: cap,
          updatedAtMs: nowMs,
        },
        {merge: true}
      );
    });

    const transcribed = await transcribeAnswers(answers, client);
    const transcript = combineTranscript(transcribed);
    if (!transcript) {
      throw new ExtractionValidationError(
        'invalid-argument',
        'no speech or text to extract'
      );
    }

    const extracted = await client.extract(transcript);
    const profile: ExtractedProfile =
      extracted.source === 'review_fixture'
        ? extracted
        : sanitizeExtractedProfile(extracted.fields, extracted.confidence, now);

    await extractionRef.set(
      {
        lastExtractedAtMs: nowMs,
        lastAttemptAtMs: nowMs,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    return {
      fields: profile.fields,
      confidence: profile.confidence,
      source: profile.source,
    };
  } catch (error) {
    throw toHttpsError(error);
  }
}

export const extractOnboardingProfile = onCall(
  {
    region: REGION,
    timeoutSeconds: 120,
    memory: '512MiB',
    secrets: [openaiApiKey],
    enforceAppCheck: ENFORCE_APPCHECK,
  },
  async (request: CallableRequest<{answers?: unknown}>) =>
    extractOnboardingProfileHandler(request, {
      db: admin.firestore(),
      now: () => new Date(),
      openaiKey: openaiApiKey.value(),
      reviewUids: process.env.ONBOARDING_AI_REVIEW_UIDS,
    })
);
