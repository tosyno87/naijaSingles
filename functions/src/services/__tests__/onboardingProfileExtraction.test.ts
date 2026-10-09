import {
  COST_CENTS_PER_EXTRACT,
  ExtractionValidationError,
  assertRateLimit,
  combineTranscript,
  dropUnder18Dob,
  isReviewFixtureUid,
  nextBudgetState,
  parseExtractionJson,
  sanitizeExtractedProfile,
  validateAnswers,
} from '../onboardingProfileExtraction';

describe('validateAnswers', () => {
  it('rejects empty input', () => {
    expect(() => validateAnswers([])).toThrow(ExtractionValidationError);
  });

  it('accepts typed answers without audio', () => {
    const answers = validateAnswers([
      {promptId: 'who', text: 'I am Ada from Houston'},
    ]);
    expect(answers).toHaveLength(1);
    expect(answers[0].audio).toBeUndefined();
  });

  it('rejects audio over 3 minutes', () => {
    const tiny = Buffer.from('aaaa').toString('base64');
    expect(() =>
      validateAnswers([
        {
          promptId: 'who',
          audioBase64: tiny,
          durationMs: 3 * 60 * 1000 + 1,
        },
      ])
    ).toThrow(/3 minutes/);
  });
});

describe('dropUnder18Dob', () => {
  const now = new Date('2026-09-03T00:00:00.000Z');

  it('keeps adult dates', () => {
    expect(dropUnder18Dob('1994-06-12', now)).toBe('1994-06-12');
  });

  it('drops under-18 dates', () => {
    expect(dropUnder18Dob('2012-01-01', now)).toBeNull();
  });
});

describe('sanitizeExtractedProfile', () => {
  const now = new Date('2026-09-03T00:00:00.000Z');

  it('omits low-confidence fields and under-18 DOB', () => {
    const profile = sanitizeExtractedProfile(
      {
        fullName: 'Ada',
        gender: 'Female',
        dateOfBirth: '2015-04-01',
        bio: 'Hello from Houston',
        lookingFor: 'Friendship',
      },
      {
        fullName: 0.9,
        gender: 0.2,
        dateOfBirth: 0.99,
        bio: 0.8,
        lookingFor: 0.9,
      },
      now
    );

    expect(profile.fields.fullName).toBe('Ada');
    expect(profile.fields.gender).toBeUndefined();
    expect(profile.fields.dateOfBirth).toBeUndefined();
    expect(profile.fields.bio).toBe('Hello from Houston');
    expect(profile.fields.lookingFor).toBe('Friendship');
  });
});

describe('parseExtractionJson', () => {
  it('reads fields and confidence', () => {
    const parsed = parseExtractionJson(
      JSON.stringify({
        fields: {fullName: 'Ada'},
        confidence: {fullName: 0.8},
      })
    );
    expect(parsed.fields.fullName).toBe('Ada');
    expect(parsed.confidence.fullName).toBe(0.8);
  });
});

describe('budget and rate limit', () => {
  it('blocks a second extract inside 24h', () => {
    expect(() => assertRateLimit(1_000, 1_000 + 60_000)).toThrow(
      /24 hours/
    );
  });

  it('resets spend on a new UTC day', () => {
    const next = nextBudgetState({
      storedDayKey: '2026-09-02',
      storedSpentCents: 1400,
      dailyCapCents: 1500,
      now: new Date('2026-09-03T00:00:00.000Z'),
      addCents: COST_CENTS_PER_EXTRACT,
    });
    expect(next.dayKey).toBe('2026-09-03');
    expect(next.spentCents).toBe(COST_CENTS_PER_EXTRACT);
  });

  it('blocks when daily cap would be exceeded', () => {
    expect(() =>
      nextBudgetState({
        storedDayKey: '2026-09-03',
        storedSpentCents: 1495,
        dailyCapCents: 1500,
        now: new Date('2026-09-03T00:00:00.000Z'),
        addCents: COST_CENTS_PER_EXTRACT,
      })
    ).toThrow(/budget/);
  });
});

describe('review fixture uid', () => {
  it('matches comma-separated env list', () => {
    expect(isReviewFixtureUid('review-1', 'review-1, other')).toBe(true);
    expect(isReviewFixtureUid('nope', 'review-1')).toBe(false);
  });
});

describe('combineTranscript', () => {
  it('joins prompt blocks', () => {
    expect(
      combineTranscript([
        {promptId: 'who', text: 'Ada'},
        {promptId: 'looking', text: 'Friends'},
      ])
    ).toContain('[who]');
  });
});
