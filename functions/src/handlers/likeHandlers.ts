/**
 * Like-related Cloud Function handlers
 */

import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import {UserService} from '../services/userService';
import {NotificationService} from '../services/notificationService';
import {SuperLike, Like} from '../types';

export class LikeHandlers {
  private userService: UserService;
  private notificationService: NotificationService;

  constructor() {
    this.userService = new UserService();
    this.notificationService = new NotificationService();
  }

  onSuperLikeCreated = onDocumentCreated('superLikes/{superLikeId}', async (event) => {
      const snap = event.data;
      if (!snap) return;
      const superLikeData = snap.data() as SuperLike;
      const superLikeId = event.params.superLikeId;
      
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
        
      } catch (error) {
        console.error('❌ Error sending super like notification:', error);
        // Log error to Firestore for monitoring
        await this.logError('super_like_created', error as Error, {superLikeId, superLikeData});
      }
    });

  onLikeCreated = onDocumentCreated('users/{userId}/LikedBy/{likeId}', async (event) => {
      const snap = event.data;
      if (!snap) return;
      const likeData = snap.data() as Like;
      const likedUserId = event.params.userId;
      const likeId = event.params.likeId;
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
        
      } catch (error) {
        console.error('❌ Error sending like notification:', error);
        // Log error to Firestore for monitoring
        await this.logError('like_created', error as Error, {likedUserId, likeId, likerId, likeData});
      }
    });

  /**
   * Log errors to Firestore for monitoring
   */
  private async logError(operation: string, error: Error, context: any): Promise<void> {
    try {
      await admin.firestore().collection('errorLogs').add({
        operation,
        error: error.message,
        stack: error.stack,
        context,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (logError) {
      console.error('Failed to log error:', logError);
    }
  }
}
