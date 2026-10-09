/**
 * One-time backfill: copy legacy root `verification` field on user docs
 * to `users/{uid}/verification/current` subcollection.
 *
 * Does NOT delete the root field — keep until all readers use subcollection.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/backfillVerificationSubcollection.ts
 *   cd functions && npx ts-node src/scripts/backfillVerificationSubcollection.ts --dry-run
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS or default application credentials.
 */
export {};
//# sourceMappingURL=backfillVerificationSubcollection.d.ts.map