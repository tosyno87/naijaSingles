/**
 * Match Quality Cloud Function handlers.
 *
 * - validateIngestion: 48-hour ingestion health check for matchQualityEvents.
 * - aggregateMetrics:  Compute KPI rates from raw events for the report CLI.
 */
/**
 * HTTPS endpoint for 48-hour ingestion validation.
 *
 * POST /validateIngestion  { "hoursBack": 48 }
 *
 * Returns a JSON report: event counts by type, schema violations, pass/fail.
 */
export declare const validateIngestion: import("firebase-functions/v2/https").HttpsFunction;
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
export declare const aggregateMetrics: import("firebase-functions/v2/https").HttpsFunction;
//# sourceMappingURL=matchQualityHandlers.d.ts.map