/**
 * Upsert public Houston unifiedGroups for Discover "Explore groups" / App Review.
 *
 * Admin-only. The Flutter app never seeds groups.
 *
 * Usage:
 *   cd functions
 *   npx ts-node src/scripts/seedHoustonReviewGroups.ts --project naijasingles-staging
 *
 * Production project ids are refused unless --i-am-sure is passed.
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or gcloud application-default login.
 * Idempotent: uses stable document ids.
 */
export {};
//# sourceMappingURL=seedHoustonReviewGroups.d.ts.map