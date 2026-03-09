/**
 * Match Quality Cloud Function handlers.
 *
 * - validateIngestion: 48-hour ingestion health check for matchQualityEvents.
 * - aggregateMetrics:  Compute KPI rates from raw events for the report CLI.
 */

import {onRequest} from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';

const COLLECTION = 'matchQualityEvents';
const REQUIRED_FIELDS = ['type', 'userIdHash', 'mode', 'timestamp'];
const EXPECTED_TYPES = [
  'impression',
  'action',
  'match',
  'conversationStart',
  'conversationQuality',
];

interface ValidationReport {
  status: 'pass' | 'fail';
  hoursBack: number;
  windowStart: string;
  windowEnd: string;
  eventCounts: Record<string, number>;
  missingTypes: string[];
  schemaViolations: SchemaViolation[];
}

interface SchemaViolation {
  docId: string;
  eventType: string;
  missingFields: string[];
}

/**
 * HTTPS endpoint for 48-hour ingestion validation.
 *
 * POST /validateIngestion  { "hoursBack": 48 }
 *
 * Returns a JSON report: event counts by type, schema violations, pass/fail.
 */
export const validateIngestion = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }

  const hoursBack: number = req.body?.hoursBack ?? 48;
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const windowStart = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - hoursBack * 60 * 60 * 1000
  );

  const eventCounts: Record<string, number> = {};
  const schemaViolations: SchemaViolation[] = [];

  for (const eventType of EXPECTED_TYPES) {
    const snapshot = await db
      .collection(COLLECTION)
      .where('type', '==', eventType)
      .where('timestamp', '>=', windowStart)
      .orderBy('timestamp', 'desc')
      .limit(100)
      .get();

    eventCounts[eventType] = snapshot.size;

    const sampleDocs = snapshot.docs.slice(0, 5);
    for (const doc of sampleDocs) {
      const data = doc.data();
      const missing = REQUIRED_FIELDS.filter((f) => !(f in data));
      if (missing.length > 0) {
        schemaViolations.push({
          docId: doc.id,
          eventType,
          missingFields: missing,
        });
      }
    }
  }

  const missingTypes = EXPECTED_TYPES.filter(
    (t) => (eventCounts[t] ?? 0) === 0
  );

  const passed =
    missingTypes.length === 0 && schemaViolations.length === 0;

  const report: ValidationReport = {
    status: passed ? 'pass' : 'fail',
    hoursBack,
    windowStart: windowStart.toDate().toISOString(),
    windowEnd: now.toDate().toISOString(),
    eventCounts,
    missingTypes,
    schemaViolations,
  };

  res.status(200).json(report);
});

interface AggregationRequest {
  startDate: string;
  endDate: string;
  experimentId?: string;
  variantId?: string;
}

interface AggregatedMetrics {
  connectToMatchRate: number;
  matchToFirstMessageRate: number;
  conversationRetention7dRate: number;
  responseRate: number;
  medianReplyDelayMs: number;
  conversationDepth: number;
  sampleSize: number;
}

/**
 * HTTPS endpoint to aggregate matchQualityEvents into KPI rates.
 *
 * POST /aggregateMetrics
 * {
 *   "startDate": "2026-03-01T00:00:00Z",
 *   "endDate":   "2026-03-15T00:00:00Z",
 *   "experimentId": "exp_match_1",   // optional
 *   "variantId":    "control"         // optional
 * }
 *
 * Returns JSON matching the MatchExperimentReportInput metrics shape.
 */
export const aggregateMetrics = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }

  const body = req.body as AggregationRequest;
  if (!body.startDate || !body.endDate) {
    res.status(400).json({error: 'startDate and endDate are required'});
    return;
  }

  const db = admin.firestore();
  const start = admin.firestore.Timestamp.fromDate(
    new Date(body.startDate)
  );
  const end = admin.firestore.Timestamp.fromDate(new Date(body.endDate));

  let baseQuery: admin.firestore.Query = db
    .collection(COLLECTION)
    .where('timestamp', '>=', start)
    .where('timestamp', '<=', end);

  if (body.experimentId) {
    baseQuery = baseQuery.where('experimentId', '==', body.experimentId);
  }
  if (body.variantId) {
    baseQuery = baseQuery.where('variantId', '==', body.variantId);
  }

  const snapshot = await baseQuery.get();

  let impressions = 0;
  let connects = 0;
  let matches = 0;
  let conversationStarts = 0;
  const userIds = new Set<string>();
  const replyDelays: number[] = [];
  let totalResponseRate = 0;
  let totalConversationDepth = 0;
  let conversationQualityCount = 0;
  let retentionQualifyingConversations = 0;
  let retainedConversations = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const type: string = data.type;

    if (data.userIdHash) {
      userIds.add(data.userIdHash);
    }

    switch (type) {
    case 'impression':
      impressions++;
      break;
    case 'action':
      if (data.actionType === 'connect' || data.actionType === 'superLike') {
        connects++;
      }
      break;
    case 'match':
      matches++;
      break;
    case 'conversationStart':
      conversationStarts++;
      break;
    case 'conversationQuality': {
      conversationQualityCount++;
      const meta = data.metadata ?? {};
      if (typeof meta.responseRate === 'number') {
        totalResponseRate += meta.responseRate;
      }
      if (typeof meta.medianReplyDelayMs === 'number') {
        replyDelays.push(meta.medianReplyDelayMs);
      }
      if (typeof meta.conversationDepth === 'number') {
        totalConversationDepth += meta.conversationDepth;
        retentionQualifyingConversations++;
        if (meta.conversationDepth >= 4) {
          retainedConversations++;
        }
      }
      break;
    }
    }
  }

  replyDelays.sort((a, b) => a - b);
  const medianReplyDelay =
    replyDelays.length > 0
      ? replyDelays[Math.floor(replyDelays.length / 2)]
      : 0;

  const metrics: AggregatedMetrics = {
    connectToMatchRate: connects > 0 ? matches / connects : 0,
    matchToFirstMessageRate: matches > 0 ? conversationStarts / matches : 0,
    conversationRetention7dRate:
      retentionQualifyingConversations > 0
        ? retainedConversations / retentionQualifyingConversations
        : 0,
    responseRate:
      conversationQualityCount > 0
        ? totalResponseRate / conversationQualityCount
        : 0,
    medianReplyDelayMs: medianReplyDelay,
    conversationDepth:
      conversationQualityCount > 0
        ? totalConversationDepth / conversationQualityCount
        : 0,
    sampleSize: userIds.size,
  };

  res.status(200).json({
    window: {
      startDate: body.startDate,
      endDate: body.endDate,
    },
    experimentId: body.experimentId ?? null,
    variantId: body.variantId ?? null,
    totalEvents: snapshot.size,
    breakdown: {
      impressions,
      connects,
      matches,
      conversationStarts,
      conversationQualityEvents: conversationQualityCount,
    },
    metrics,
  });
});
