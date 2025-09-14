/**
 * User service for handling user-related operations
 */
import { User } from '../types';
export declare class UserService {
    private db;
    constructor();
    /**
     * Get user by ID
     */
    getUserById(userId: string): Promise<User | null>;
    /**
     * Get multiple users by IDs
     */
    getUsersByIds(userIds: string[]): Promise<User[]>;
    /**
     * Validate user exists and has required fields
     */
    validateUser(user: User): boolean;
    /**
     * Helper function to chunk array into smaller arrays
     */
    private chunkArray;
}
//# sourceMappingURL=userService.d.ts.map