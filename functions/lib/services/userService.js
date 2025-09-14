"use strict";
/**
 * User service for handling user-related operations
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserService = void 0;
const admin = __importStar(require("firebase-admin"));
class UserService {
    constructor() {
        this.db = admin.firestore();
    }
    /**
     * Get user by ID
     */
    async getUserById(userId) {
        try {
            const userDoc = await this.db.collection('users').doc(userId).get();
            if (!userDoc.exists) {
                console.log(`User not found: ${userId}`);
                return null;
            }
            return Object.assign({ id: userId }, userDoc.data());
        }
        catch (error) {
            console.error(`Error getting user ${userId}:`, error);
            throw error;
        }
    }
    /**
     * Get multiple users by IDs
     */
    async getUsersByIds(userIds) {
        try {
            const users = [];
            // Firestore has a limit of 10 items per 'in' query
            const chunks = this.chunkArray(userIds, 10);
            for (const chunk of chunks) {
                const userDocs = await this.db.collection('users')
                    .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
                    .get();
                userDocs.forEach(doc => {
                    if (doc.exists) {
                        users.push(Object.assign({ id: doc.id }, doc.data()));
                    }
                });
            }
            return users;
        }
        catch (error) {
            console.error('Error getting users by IDs:', error);
            throw error;
        }
    }
    /**
     * Validate user exists and has required fields
     */
    validateUser(user) {
        if (!user.id) {
            console.log('User validation failed: missing ID');
            return false;
        }
        return true;
    }
    /**
     * Helper function to chunk array into smaller arrays
     */
    chunkArray(array, size) {
        const chunks = [];
        for (let i = 0; i < array.length; i += size) {
            chunks.push(array.slice(i, i + size));
        }
        return chunks;
    }
}
exports.UserService = UserService;
//# sourceMappingURL=userService.js.map