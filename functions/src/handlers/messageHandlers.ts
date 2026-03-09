/**
 * Message-related Cloud Function handlers
 */

import {onDocumentCreated} from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import {UserService} from '../services/userService';
import {NotificationService} from '../services/notificationService';
import {Message, ChatThread} from '../types';

export class MessageHandlers {
  private userService: UserService;
  private notificationService: NotificationService;

  constructor() {
    this.userService = new UserService();
    this.notificationService = new NotificationService();
  }

  onMessageSent = onDocumentCreated('chatThreads/{threadId}/messages/{messageId}', async (event) => {
      const snap = event.data;
      if (!snap) return;
      const messageData = snap.data() as Message;
      const threadId = event.params.threadId;
      const messageId = event.params.messageId;
      
      console.log(`💬 New message in thread ${threadId}:`, messageData);
      
      try {
        // Get chat thread to find recipient
        const threadDoc = await admin.firestore()
          .collection('chatThreads').doc(threadId).get();
        
        if (!threadDoc.exists) {
          console.log('Chat thread not found');
          return;
        }
        
        const threadData = threadDoc.data() as ChatThread;
        const participants = threadData.userIds || [];
        const senderId = messageData.senderId;
        const recipientId = participants.find(id => id !== senderId);
        
        if (!recipientId) {
          console.log('Recipient not found in thread');
          return;
        }
        
        // Get sender and recipient data
        const [sender, recipient] = await Promise.all([
          this.userService.getUserById(senderId),
          this.userService.getUserById(recipientId)
        ]);
        
        if (!sender || !recipient) {
          console.log('Sender or recipient not found');
          return;
        }
        
        // Validate users
        if (!this.userService.validateUser(sender) || !this.userService.validateUser(recipient)) {
          console.log('Invalid user data');
          return;
        }
        
        await this.notificationService.sendMessageNotification(recipient, sender, messageData, threadId);
        
        console.log('✅ Message notification sent successfully');
        
      } catch (error) {
        console.error('❌ Error sending message notification:', error);
        // Log error to Firestore for monitoring
        await this.logError('message_sent', error as Error, {threadId, messageId, messageData});
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
