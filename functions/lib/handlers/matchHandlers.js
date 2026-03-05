"use strict";
/**
 * Match-related Cloud Function handlers
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
exports.MatchHandlers = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const userService_1 = require("../services/userService");
const notificationService_1 = require("../services/notificationService");
class MatchHandlers {
    constructor() {
        this.onMatchCreated = (0, firestore_1.onDocumentCreated)('matches/{matchId}', async (event) => {
            const snap = event.data;
            if (!snap)
                return;
            const matchData = snap.data();
            const matchId = event.params.matchId;
            console.log(`🎉 New match created: ${matchId}`, matchData);
            try {
                const users = matchData.users || [];
                if (users.length !== 2) {
                    console.log('Invalid match - not exactly 2 users');
                    return;
                }
                // Get both users' data in parallel
                const [userA, userB] = await Promise.all([
                    this.userService.getUserById(users[0]),
                    this.userService.getUserById(users[1])
                ]);
                if (!userA || !userB) {
                    console.log('One or both users not found');
                    return;
                }
                // Validate users
                if (!this.userService.validateUser(userA) || !this.userService.validateUser(userB)) {
                    console.log('Invalid user data');
                    return;
                }
                // Send match notifications to both users
                await Promise.all([
                    this.notificationService.sendMatchNotification(userA, userB),
                    this.notificationService.sendMatchNotification(userB, userA)
                ]);
                console.log('✅ Match notifications sent successfully');
            }
            catch (error) {
                console.error('❌ Error sending match notification:', error);
                // Log error to Firestore for monitoring
                await this.logError('match_created', error, { matchId, matchData });
            }
        });
        this.userService = new userService_1.UserService();
        this.notificationService = new notificationService_1.NotificationService();
    }
    /**
     * Log errors to Firestore for monitoring
     */
    async logError(operation, error, context) {
        try {
            await admin.firestore().collection('errorLogs').add({
                operation,
                error: error.message,
                stack: error.stack,
                context,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        catch (logError) {
            console.error('Failed to log error:', logError);
        }
    }
}
exports.MatchHandlers = MatchHandlers;
//# sourceMappingURL=matchHandlers.js.map