/**
 * Seeds the `runtimeConfig/matchTuning` document with default config and
 * an inactive experiment block.
 *
 * Safe to run multiple times -- skips if the document already exists
 * unless --force is passed.
 *
 * Run with:
 *   cd functions && npx ts-node src/scripts/seedMatchTuningConfig.ts
 *   cd functions && npx ts-node src/scripts/seedMatchTuningConfig.ts --force
 *
 * Requires GOOGLE_APPLICATION_CREDENTIALS to point at a service-account key,
 * or run from a Cloud Shell that already has default credentials.
 */
export {};
//# sourceMappingURL=seedMatchTuningConfig.d.ts.map