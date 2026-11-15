"use strict";
/**
 * Pure helpers for conversational onboarding extraction.
 * Cost caps, schema sanitization, and review-fixture data live here so
 * handlers and tests share one source of truth.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.EXTRACTION_SYSTEM_PROMPT = exports.REVIEW_FIXTURE = exports.ExtractionValidationError = exports.RATE_LIMIT_MS = exports.DEFAULT_DAILY_CAP_CENTS = exports.COST_CENTS_PER_EXTRACT = exports.DOB_MIN_CONFIDENCE = exports.MIN_CONFIDENCE = exports.MAX_TOTAL_TEXT_CHARS = exports.MAX_TEXT_CHARS_PER_ANSWER = exports.MAX_PROMPT_ID_LENGTH = exports.MAX_ANSWERS = exports.MAX_AUDIO_BYTES = exports.MAX_DURATION_MS = void 0;
exports.utcDayKey = utcDayKey;
exports.isReviewFixtureUid = isReviewFixtureUid;
exports.ageFromIsoDate = ageFromIsoDate;
exports.dropUnder18Dob = dropUnder18Dob;
exports.validateAnswers = validateAnswers;
exports.combineTranscript = combineTranscript;
exports.sanitizeExtractedProfile = sanitizeExtractedProfile;
exports.parseExtractionJson = parseExtractionJson;
exports.assertRateLimit = assertRateLimit;
exports.nextBudgetState = nextBudgetState;
exports.MAX_DURATION_MS = 3 * 60 * 1000;
exports.MAX_AUDIO_BYTES = 2 * 1024 * 1024;
exports.MAX_ANSWERS = 5;
/** Prevents OpenAI cost amplification via oversized typed answers. */
exports.MAX_PROMPT_ID_LENGTH = 64;
exports.MAX_TEXT_CHARS_PER_ANSWER = 2000;
exports.MAX_TOTAL_TEXT_CHARS = 6000;
exports.MIN_CONFIDENCE = 0.5;
exports.DOB_MIN_CONFIDENCE = 0.7;
exports.COST_CENTS_PER_EXTRACT = 8;
exports.DEFAULT_DAILY_CAP_CENTS = 1500;
exports.RATE_LIMIT_MS = 24 * 60 * 60 * 1000;
const ALLOWED_GENDERS = new Set([
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
    'Other',
]);
const ALLOWED_LOOKING_FOR = new Set(['Dating', 'Friendship', 'Networking']);
const ALLOWED_INTERESTED_IN = new Set(['everyone', 'Male', 'Female']);
class ExtractionValidationError extends Error {
    code;
    constructor(code, message) {
        super(message);
        this.code = code;
        this.name = 'ExtractionValidationError';
    }
}
exports.ExtractionValidationError = ExtractionValidationError;
function utcDayKey(now) {
    return now.toISOString().slice(0, 10);
}
function isReviewFixtureUid(uid, envUids) {
    if (!envUids) {
        return false;
    }
    return envUids
        .split(',')
        .map((s) => s.trim())
        .filter((s) => s.length > 0)
        .includes(uid);
}
function ageFromIsoDate(iso, now) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso);
    if (!match) {
        return null;
    }
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    if (month < 1 || month > 12 || day < 1 || day > 31) {
        return null;
    }
    let age = now.getUTCFullYear() - year;
    const monthNow = now.getUTCMonth() + 1;
    const dayNow = now.getUTCDate();
    if (monthNow < month || (monthNow === month && dayNow < day)) {
        age -= 1;
    }
    return age;
}
function dropUnder18Dob(iso, now) {
    if (!iso) {
        return null;
    }
    const age = ageFromIsoDate(iso, now);
    if (age === null || age < 18) {
        return null;
    }
    return iso;
}
function asString(value) {
    return typeof value === 'string' ? value.trim() : '';
}
function asStringList(value, max = 12) {
    if (!Array.isArray(value)) {
        return [];
    }
    const out = [];
    for (const item of value) {
        const text = asString(item);
        if (text.length > 0 && !out.includes(text)) {
            out.push(text);
        }
        if (out.length >= max) {
            break;
        }
    }
    return out;
}
function decodeAudio(base64) {
    const compact = base64.replace(/\s/g, '');
    if (!/^[A-Za-z0-9+/=]+$/.test(compact) || compact.length < 8) {
        throw new ExtractionValidationError('invalid-argument', 'audioBase64 is not valid base64');
    }
    return Buffer.from(compact, 'base64');
}
function validateAnswers(raw) {
    if (!Array.isArray(raw) || raw.length === 0) {
        throw new ExtractionValidationError('invalid-argument', 'answers must be a non-empty array');
    }
    if (raw.length > exports.MAX_ANSWERS) {
        throw new ExtractionValidationError('invalid-argument', `at most ${exports.MAX_ANSWERS} answers are allowed`);
    }
    let totalDuration = 0;
    let totalBytes = 0;
    const answers = [];
    for (const item of raw) {
        if (item === null || typeof item !== 'object') {
            throw new ExtractionValidationError('invalid-argument', 'each answer must be an object');
        }
        const row = item;
        const promptId = asString(row.promptId);
        if (!promptId) {
            throw new ExtractionValidationError('invalid-argument', 'promptId is required');
        }
        if (promptId.length > exports.MAX_PROMPT_ID_LENGTH) {
            throw new ExtractionValidationError('invalid-argument', `promptId exceeds ${exports.MAX_PROMPT_ID_LENGTH} characters`);
        }
        const text = asString(row.text);
        if (text.length > exports.MAX_TEXT_CHARS_PER_ANSWER) {
            throw new ExtractionValidationError('invalid-argument', `each answer text must be at most ${exports.MAX_TEXT_CHARS_PER_ANSWER} characters`);
        }
        const audioBase64 = asString(row.audioBase64);
        const mimeType = asString(row.mimeType) || 'audio/mp4';
        const durationMs = typeof row.durationMs === 'number' && Number.isFinite(row.durationMs)
            ? Math.max(0, Math.round(row.durationMs))
            : 0;
        if (!text && !audioBase64) {
            throw new ExtractionValidationError('invalid-argument', 'each answer needs text or audio');
        }
        const validated = { promptId, text };
        if (audioBase64) {
            if (durationMs <= 0) {
                throw new ExtractionValidationError('invalid-argument', 'audio answers require durationMs');
            }
            const buffer = decodeAudio(audioBase64);
            totalDuration += durationMs;
            totalBytes += buffer.length;
            if (totalDuration > exports.MAX_DURATION_MS) {
                throw new ExtractionValidationError('invalid-argument', 'total audio exceeds 3 minutes');
            }
            if (totalBytes > exports.MAX_AUDIO_BYTES) {
                throw new ExtractionValidationError('invalid-argument', 'audio payload is too large');
            }
            validated.audio = { buffer, mimeType, durationMs };
        }
        answers.push(validated);
    }
    const totalTextChars = answers.reduce((sum, a) => sum + a.text.length, 0);
    if (totalTextChars > exports.MAX_TOTAL_TEXT_CHARS) {
        throw new ExtractionValidationError('invalid-argument', `combined answer text exceeds ${exports.MAX_TOTAL_TEXT_CHARS} characters`);
    }
    return answers;
}
function combineTranscript(answers) {
    return answers
        .map((a) => `[${a.promptId}]\n${a.text}`)
        .join('\n\n')
        .trim();
}
function pickConfidentString(value, confidence, min = exports.MIN_CONFIDENCE) {
    if (confidence < min) {
        return '';
    }
    return asString(value);
}
function sanitizeExtractedProfile(rawFields, rawConfidence, now) {
    const confidence = {};
    for (const [key, value] of Object.entries(rawConfidence)) {
        if (typeof value === 'number' && Number.isFinite(value)) {
            confidence[key] = Math.min(1, Math.max(0, value));
        }
    }
    const fields = {};
    const fullName = pickConfidentString(rawFields.fullName, confidence.fullName ?? 0);
    if (fullName) {
        fields.fullName = fullName.slice(0, 80);
    }
    const genderRaw = pickConfidentString(rawFields.gender, confidence.gender ?? 0);
    if (ALLOWED_GENDERS.has(genderRaw)) {
        fields.gender = genderRaw;
    }
    const dobConfidence = confidence.dateOfBirth ?? 0;
    const dobRaw = asString(rawFields.dateOfBirth);
    if (dobConfidence >= exports.DOB_MIN_CONFIDENCE && dobRaw) {
        const safeDob = dropUnder18Dob(dobRaw, now);
        if (safeDob) {
            fields.dateOfBirth = safeDob;
        }
    }
    const bio = pickConfidentString(rawFields.bio, confidence.bio ?? 0);
    if (bio) {
        fields.bio = bio.slice(0, 600);
    }
    const tribe = pickConfidentString(rawFields.tribe, confidence.tribe ?? 0);
    if (tribe) {
        fields.tribe = tribe.slice(0, 60);
    }
    const nationality = pickConfidentString(rawFields.nationality, confidence.nationality ?? 0);
    if (nationality) {
        fields.nationality = nationality.slice(0, 60);
    }
    const occupation = pickConfidentString(rawFields.occupation, confidence.occupation ?? 0);
    if (occupation) {
        fields.occupation = occupation.slice(0, 80);
    }
    const education = pickConfidentString(rawFields.education, confidence.education ?? 0);
    if (education) {
        fields.education = education.slice(0, 80);
    }
    const religion = pickConfidentString(rawFields.religion, confidence.religion ?? 0);
    if (religion) {
        fields.religion = religion.slice(0, 60);
    }
    const lookingForRaw = pickConfidentString(rawFields.lookingFor, confidence.lookingFor ?? 0);
    if (ALLOWED_LOOKING_FOR.has(lookingForRaw)) {
        fields.lookingFor = lookingForRaw;
    }
    const interestedInRaw = pickConfidentString(rawFields.interestedIn, confidence.interestedIn ?? 0);
    if (ALLOWED_INTERESTED_IN.has(interestedInRaw)) {
        fields.interestedIn = interestedInRaw;
    }
    const languages = asStringList(rawFields.languages);
    if (languages.length > 0 && (confidence.languages ?? 0) >= exports.MIN_CONFIDENCE) {
        fields.languages = languages;
    }
    const interests = asStringList(rawFields.interests);
    if (interests.length > 0 && (confidence.interests ?? 0) >= exports.MIN_CONFIDENCE) {
        fields.interests = interests;
    }
    const values = asStringList(rawFields.values);
    if (values.length > 0 && (confidence.values ?? 0) >= exports.MIN_CONFIDENCE) {
        fields.values = values;
    }
    const dealbreakers = asStringList(rawFields.dealbreakers);
    if (dealbreakers.length > 0 &&
        (confidence.dealbreakers ?? 0) >= exports.MIN_CONFIDENCE) {
        fields.dealbreakers = dealbreakers;
    }
    const weekendVibe = pickConfidentString(rawFields.weekendVibe, confidence.weekendVibe ?? 0);
    if (weekendVibe) {
        fields.weekendVibe = weekendVibe.slice(0, 80);
    }
    const fashionStyle = pickConfidentString(rawFields.fashionStyle, confidence.fashionStyle ?? 0);
    if (fashionStyle) {
        fields.fashionStyle = fashionStyle.slice(0, 80);
    }
    const drinkingPreference = pickConfidentString(rawFields.drinkingPreference, confidence.drinkingPreference ?? 0);
    if (drinkingPreference) {
        fields.drinkingPreference = drinkingPreference.slice(0, 40);
    }
    const smokingPreference = pickConfidentString(rawFields.smokingPreference, confidence.smokingPreference ?? 0);
    if (smokingPreference) {
        fields.smokingPreference = smokingPreference.slice(0, 40);
    }
    const relationshipIntent = pickConfidentString(rawFields.relationshipIntent, confidence.relationshipIntent ?? 0);
    if (relationshipIntent) {
        fields.relationshipIntent = relationshipIntent.slice(0, 80);
    }
    return { fields, confidence, source: 'model' };
}
function parseExtractionJson(raw) {
    let parsed;
    try {
        parsed = JSON.parse(raw);
    }
    catch {
        throw new ExtractionValidationError('failed-precondition', 'model returned invalid JSON');
    }
    if (parsed === null || typeof parsed !== 'object') {
        throw new ExtractionValidationError('failed-precondition', 'model JSON must be an object');
    }
    const root = parsed;
    const fields = root.fields !== null && typeof root.fields === 'object'
        ? root.fields
        : root;
    const confidenceRaw = root.confidence !== null && typeof root.confidence === 'object'
        ? root.confidence
        : {};
    const confidence = {};
    for (const [key, value] of Object.entries(confidenceRaw)) {
        if (typeof value === 'number' && Number.isFinite(value)) {
            confidence[key] = value;
        }
    }
    return { fields, confidence };
}
function assertRateLimit(lastExtractedAtMs, nowMs) {
    if (lastExtractedAtMs === null) {
        return;
    }
    if (nowMs - lastExtractedAtMs < exports.RATE_LIMIT_MS) {
        throw new ExtractionValidationError('resource-exhausted', 'only one profile draft per 24 hours');
    }
}
function nextBudgetState(args) {
    const today = utcDayKey(args.now);
    const spent = args.storedDayKey === today ? (args.storedSpentCents ?? 0) : 0;
    if (spent + args.addCents > args.dailyCapCents) {
        throw new ExtractionValidationError('resource-exhausted', 'daily AI onboarding budget reached');
    }
    return { dayKey: today, spentCents: spent + args.addCents };
}
exports.REVIEW_FIXTURE = {
    source: 'review_fixture',
    confidence: {
        fullName: 0.95,
        gender: 0.9,
        dateOfBirth: 0.85,
        bio: 0.95,
        tribe: 0.9,
        languages: 0.9,
        lookingFor: 0.9,
        nationality: 0.9,
        interests: 0.85,
    },
    fields: {
        fullName: 'Adaeze Okonkwo',
        gender: 'Female',
        dateOfBirth: '1994-06-12',
        bio: 'Houston-based Nigerian in the diaspora. I love Afrobeats nights, ' +
            'community events, and meeting people who get the culture without a lecture.',
        tribe: 'Igbo',
        languages: ['English', 'Igbo'],
        lookingFor: 'Friendship',
        nationality: 'Nigeria',
        interests: ['music', 'community events', 'food'],
        occupation: 'Product designer',
    },
};
exports.EXTRACTION_SYSTEM_PROMPT = `You extract a structured AfroPeep community profile from a user's own words.
Return JSON only with keys "fields" and "confidence".
fields may include: fullName, dateOfBirth (YYYY-MM-DD), gender (Male|Female|Non-binary|Prefer not to say|Other), bio, tribe, nationality, occupation, education, religion, lookingFor (Dating|Friendship|Networking), interestedIn (everyone|Male|Female), languages (string[]), interests (string[]), values (string[]), dealbreakers (string[]), weekendVibe, fashionStyle, drinkingPreference, smokingPreference, relationshipIntent.
confidence is 0-1 per field. If unsure, omit the field or use confidence below 0.5.
Never invent a date of birth. Never set dateOfBirth if the speaker did not clearly state one. Do not infer a home address.`;
//# sourceMappingURL=onboardingProfileExtraction.js.map