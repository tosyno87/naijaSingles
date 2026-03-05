/**
 * Test user creation Cloud Function handlers
 * Used for development and testing purposes
 */
export declare class TestUserHandlers {
    private readonly maleNames;
    private readonly femaleNames;
    private readonly lastNames;
    private readonly interests;
    private readonly occupations;
    private readonly educationLevels;
    /**
     * Create test users for development/testing
     * Requires admin secret token in Authorization header for security
     */
    createTestUsers: import("firebase-functions/v2/https").HttpsFunction;
    /**
     * Create users in parallel batches with error handling
     */
    private createUsersInBatches;
    /**
     * Create a single test user with proper error handling
     */
    private createTestUser;
    /**
     * Generate a random bio based on interests and occupation
     */
    private generateBio;
    /**
     * Log errors to Firestore for monitoring (consistent with other handlers)
     */
    private logError;
    /**
     * Delay helper for rate limiting
     */
    private delay;
}
//# sourceMappingURL=testUserHandlers.d.ts.map