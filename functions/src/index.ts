/**
 * NaijaSingles Cloud Functions - TypeScript Implementation
 * 
 * This file exports all Cloud Functions for the NaijaSingles application.
 * The functions are organized into modular handlers for better maintainability.
 */

import * as admin from 'firebase-admin';
import {onRequest} from 'firebase-functions/v2/https';
import {MatchHandlers} from './handlers/matchHandlers';
import {MessageHandlers} from './handlers/messageHandlers';
import {LikeHandlers} from './handlers/likeHandlers';
import {TestUserHandlers} from './handlers/testUserHandlers';
import {DiscoverabilityHandlers} from './handlers/discoverabilityHandlers';

admin.initializeApp();

const matchHandlers = new MatchHandlers();
const messageHandlers = new MessageHandlers();
const likeHandlers = new LikeHandlers();
const testUserHandlers = new TestUserHandlers();
const discoverabilityHandlers = new DiscoverabilityHandlers();

export const onMatchCreated = matchHandlers.onMatchCreated;
export const onMessageSent = messageHandlers.onMessageSent;
export const onSuperLikeCreated = likeHandlers.onSuperLikeCreated;
export const onLikeCreated = likeHandlers.onLikeCreated;
export const onUserWritten = discoverabilityHandlers.onUserWritten;

const isTestEnvEnabled = process.env.ENABLE_TEST_ENDPOINTS === 'true';
export const createTestUsers = isTestEnvEnabled
  ? testUserHandlers.createTestUsers
  : onRequest((req, res) => {
      res.status(404).json({error: 'Not available in production'});
    });

export const healthCheck = onRequest((req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

