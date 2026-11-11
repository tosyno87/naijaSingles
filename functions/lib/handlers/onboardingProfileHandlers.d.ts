/**
 * Authenticated callable: transcribe prompted answers and extract a draft profile.
 * Audio is processed in memory and discarded. Rate-limited to 1 extract / uid / 24h.
 */
import { CallableRequest } from 'firebase-functions/v2/https';
import { ExtractedProfile } from '../services/onboardingProfileExtraction';
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
export declare function createOpenAiClient(apiKey: string): OpenAiClient;
export declare function extractOnboardingProfileHandler(request: CallableRequest<{
    answers?: unknown;
}>, deps: ExtractOnboardingDeps): Promise<{
    fields: Record<string, unknown>;
    confidence: Record<string, number>;
    source: string;
}>;
export declare const extractOnboardingProfile: import("firebase-functions/v2/https").CallableFunction<{
    answers?: unknown;
}, Promise<{
    fields: Record<string, unknown>;
    confidence: Record<string, number>;
    source: string;
}>, unknown>;
//# sourceMappingURL=onboardingProfileHandlers.d.ts.map