/**
 * NaijaSingles Cloud Functions - TypeScript Implementation
 * 
 * This file exports all Cloud Functions for the NaijaSingles application.
 * The functions are organized into modular handlers for better maintainability.
 */

import * as admin from 'firebase-admin';
import {MatchHandlers} from './handlers/matchHandlers';
import {MessageHandlers} from './handlers/messageHandlers';
import {LikeHandlers} from './handlers/likeHandlers';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize handlers
const matchHandlers = new MatchHandlers();
const messageHandlers = new MessageHandlers();
const likeHandlers = new LikeHandlers();

// Export all Cloud Functions

// Match-related functions
export const onMatchCreated = matchHandlers.onMatchCreated;

// Message-related functions
export const onMessageSent = messageHandlers.onMessageSent;

// Like-related functions
export const onSuperLikeCreated = likeHandlers.onSuperLikeCreated;
export const onLikeCreated = likeHandlers.onLikeCreated;

// Health check function
export const healthCheck = async (req: any, res: any) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
};
