/**
 * Match-related Cloud Function handlers
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import {UserService} from '../services/userService';
import {NotificationService} from '../services/notificationService';
import {Match} from '../types';

export class MatchHandlers {
  private userService: UserService;
  private notificationService: NotificationService;

  constructor() {
    this.userService = new UserService();
    this.notificationService = new NotificationService();
  }

  /**
   * Handle match creation (Gen 1 - compatible with existing deployments)
   */
  onMatchCreated = functions.firestore
    .document('matches/{matchId}')
    .onCreate(async (snap: admin.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
      const matchData = snap.data() as Match;
      const matchId = context.params.matchId;
      
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
        
      } catch (error) {
        console.error('❌ Error sending match notification:', error);
        // Log error to Firestore for monitoring
        await this.logError('match_created', error as Error, {matchId, matchData});
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
