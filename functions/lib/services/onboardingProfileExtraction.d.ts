/**
 * Pure helpers for conversational onboarding extraction.
 * Cost caps, schema sanitization, and review-fixture data live here so
 * handlers and tests share one source of truth.
 */
export declare const MAX_DURATION_MS: number;
export declare const MAX_AUDIO_BYTES: number;
export declare const MAX_ANSWERS = 5;
/** Prevents OpenAI cost amplification via oversized typed answers. */
export declare const MAX_PROMPT_ID_LENGTH = 64;
export declare const MAX_TEXT_CHARS_PER_ANSWER = 2000;
export declare const MAX_TOTAL_TEXT_CHARS = 6000;
export declare const MIN_CONFIDENCE = 0.5;
export declare const DOB_MIN_CONFIDENCE = 0.7;
export declare const COST_CENTS_PER_EXTRACT = 8;
export declare const DEFAULT_DAILY_CAP_CENTS = 1500;
export declare const RATE_LIMIT_MS: number;
export type ValidatedAudio = {
    buffer: Buffer;
    mimeType: string;
    durationMs: number;
};
export type ValidatedAnswer = {
    promptId: string;
    text: string;
    audio?: ValidatedAudio;
};
export type ExtractedProfile = {
    fields: Record<string, unknown>;
    confidence: Record<string, number>;
    source: 'model' | 'review_fixture';
};
export declare class ExtractionValidationError extends Error {
    readonly code: 'invalid-argument' | 'resource-exhausted' | 'failed-precondition';
    constructor(code: 'invalid-argument' | 'resource-exhausted' | 'failed-precondition', message: string);
}
export declare function utcDayKey(now: Date): string;
export declare function isReviewFixtureUid(uid: string, envUids: string | undefined): boolean;
export declare function ageFromIsoDate(iso: string, now: Date): number | null;
export declare function dropUnder18Dob(iso: string | null, now: Date): string | null;
export declare function validateAnswers(raw: unknown): ValidatedAnswer[];
export declare function combineTranscript(answers: Array<{
    promptId: string;
    text: string;
}>): string;
export declare function sanitizeExtractedProfile(rawFields: Record<string, unknown>, rawConfidence: Record<string, number>, now: Date): ExtractedProfile;
export declare function parseExtractionJson(raw: string): {
    fields: Record<string, unknown>;
    confidence: Record<string, number>;
};
export declare function assertRateLimit(lastExtractedAtMs: number | null, nowMs: number): void;
export declare function nextBudgetState(args: {
    storedDayKey: string | undefined;
    storedSpentCents: number | undefined;
    dailyCapCents: number;
    now: Date;
    addCents: number;
}): {
    dayKey: string;
    spentCents: number;
};
export declare const REVIEW_FIXTURE: ExtractedProfile;
export declare const EXTRACTION_SYSTEM_PROMPT = "You extract a structured AfroPeep community profile from a user's own words.\nReturn JSON only with keys \"fields\" and \"confidence\".\nfields may include: fullName, dateOfBirth (YYYY-MM-DD), gender (Male|Female|Non-binary|Prefer not to say|Other), bio, tribe, nationality, occupation, education, religion, lookingFor (Dating|Friendship|Networking), interestedIn (everyone|Male|Female), languages (string[]), interests (string[]), values (string[]), dealbreakers (string[]), weekendVibe, fashionStyle, drinkingPreference, smokingPreference, relationshipIntent.\nconfidence is 0-1 per field. If unsure, omit the field or use confidence below 0.5.\nNever invent a date of birth. Never set dateOfBirth if the speaker did not clearly state one. Do not infer a home address.";
//# sourceMappingURL=onboardingProfileExtraction.d.ts.map