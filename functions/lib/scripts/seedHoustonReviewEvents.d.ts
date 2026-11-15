/**
 * Upsert two published Houston weekend events for Discover home / App Review.
 *
 * Admin-only. The Flutter app never seeds events.
 *
 * Usage:
 *   cd functions
 *   npx ts-node src/scripts/seedHoustonReviewEvents.ts --project naijasingles-staging
 *
 * Production project ids are refused unless --i-am-sure is passed:
 *   npx ts-node src/scripts/seedHoustonReviewEvents.ts \
 *     --project naijasingles-74a75 --i-am-sure
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default login.
 * Idempotent: uses stable document ids and overwrites the same two docs.
 */
export declare function parseArgs(argv: string[]): Record<string, string>;
export declare function assertProjectAllowed(projectId: string, iAmSure: boolean): void;
//# sourceMappingURL=seedHoustonReviewEvents.d.ts.map