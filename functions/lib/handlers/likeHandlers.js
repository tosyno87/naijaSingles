"use strict";
/**
 * Like-related Cloud Function handlers
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
exports.LikeHandlers = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const userService_1 = require("../services/userService");
const notificationService_1 = require("../services/notificationService");
class LikeHandlers {
    constructor() {
        /**
         * Handle super like creation
         */
        this.onSuperLikeCreated = functions.firestore
            .document('superLikes/{superLikeId}')
            .onCreate(async (snap, context) => {
            const superLikeData = snap.data();
            const superLikeId = context.params.superLikeId;
            console.log(`⭐ New super like created: ${superLikeId}`, superLikeData);
            try {
                const fromUserId = superLikeData.fromUserId;
                const toUserId = superLikeData.toUserId;
                if (!fromUserId || !toUserId) {
                    console.log('Invalid super like - missing user IDs');
                    return;
                }
                // Get both users' data
                const [fromUser, toUser] = await Promise.all([
                    this.userService.getUserById(fromUserId),
                    this.userService.getUserById(toUserId)
                ]);
                if (!fromUser || !toUser) {
                    console.log('One or both users not found for super like');
                    return;
                }
                // Validate users
                if (!this.userService.validateUser(fromUser) || !this.userService.validateUser(toUser)) {
                    console.log('Invalid user data for super like');
                    return;
                }
                await this.notificationService.sendSuperLikeNotification(toUser, fromUser, superLikeId);
                console.log('✅ Super like notification sent successfully');
            }
            catch (error) {
                console.error('❌ Error sending super like notification:', error);
                // Log error to Firestore for monitoring
                await this.logError('super_like_created', error, { superLikeId, superLikeData });
            }
        });
        /**
         * Handle like creation
         */
        this.onLikeCreated = functions.firestore
            .document('users/{userId}/LikedBy/{likeId}')
            .onCreate(async (snap, context) => {
            const likeData = snap.data();
            const likedUserId = context.params.userId;
            const likeId = context.params.likeId;
            const likerId = likeData.LikedBy;
            console.log(`💖 New like: ${likerId} liked ${likedUserId}`);
            try {
                // Get both users' data
                const [likedUser, liker] = await Promise.all([
                    this.userService.getUserById(likedUserId),
                    this.userService.getUserById(likerId)
                ]);
                if (!likedUser || !liker) {
                    console.log('Liked user or liker not found');
                    return;
                }
                // Validate users
                if (!this.userService.validateUser(likedUser) || !this.userService.validateUser(liker)) {
                    console.log('Invalid user data for like');
                    return;
                }
                await this.notificationService.sendLikeNotification(likedUser, liker);
                console.log('✅ Like notification sent successfully');
            }
            catch (error) {
                console.error('❌ Error sending like notification:', error);
                // Log error to Firestore for monitoring
                await this.logError('like_created', error, { likedUserId, likeId, likerId, likeData });
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
exports.LikeHandlers = LikeHandlers;
//# sourceMappingURL=likeHandlers.js.map