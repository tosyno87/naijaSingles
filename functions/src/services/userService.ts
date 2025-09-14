/**
 * User service for handling user-related operations
 */

import * as admin from 'firebase-admin';
import {User} from '../types';

export class UserService {
  private db: admin.firestore.Firestore;

  constructor() {
    this.db = admin.firestore();
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: string): Promise<User | null> {
    try {
      const userDoc = await this.db.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.log(`User not found: ${userId}`);
        return null;
      }

      return {id: userId, ...userDoc.data()} as User;
    } catch (error) {
      console.error(`Error getting user ${userId}:`, error);
      throw error;
    }
  }

  /**
   * Get multiple users by IDs
   */
  async getUsersByIds(userIds: string[]): Promise<User[]> {
    try {
      const users: User[] = [];
      
      // Firestore has a limit of 10 items per 'in' query
      const chunks = this.chunkArray(userIds, 10);
      
      for (const chunk of chunks) {
        const userDocs = await this.db.collection('users')
          .where(admin.firestore.FieldPath.documentId(), 'in', chunk)
          .get();
          
        userDocs.forEach(doc => {
          if (doc.exists) {
            users.push({id: doc.id, ...doc.data()} as User);
          }
        });
      }
      
      return users;
    } catch (error) {
      console.error('Error getting users by IDs:', error);
      throw error;
    }
  }

  /**
   * Validate user exists and has required fields
   */
  validateUser(user: User): boolean {
    if (!user.id) {
      console.log('User validation failed: missing ID');
      return false;
    }
    
    return true;
  }

  /**
   * Helper function to chunk array into smaller arrays
   */
  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }
}
