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
import {
  validateIngestion,
  aggregateMetrics,
} from './handlers/matchQualityHandlers';

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

export {validateIngestion, aggregateMetrics};

export const healthCheck = onRequest((req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

export const seedMatchTuningConfig = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }
  const force = req.body?.force === true;
  const db = admin.firestore();
  const docRef = db.collection('runtimeConfig').doc('matchTuning');

  if (!force) {
    const existing = await docRef.get();
    if (existing.exists) {
      res.status(200).json({status: 'skipped', reason: 'document already exists'});
      return;
    }
  }

  const payload = {
    version: '1.0.0',
    rollbackKey: 'v0_defaults',
    datingWeights: {age: 0.30, location: 0.25, lifestyle: 0.20, interest: 0.15, completeness: 0.10},
    friendshipWeights: {social: 0.35, interest: 0.25, location: 0.20, age: 0.10, completeness: 0.10},
    networkingWeights: {professional: 0.40, industry: 0.25, location: 0.20, completeness: 0.15},
    locationPerfectMiles: 5.0,
    locationDecayMiles: 50.0,
    locationFloorScore: 0.2,
    experiment: {active: false},
  };

  await docRef.set({payload, updatedAt: admin.firestore.FieldValue.serverTimestamp()});
  res.status(200).json({status: 'seeded', version: payload.version});
});

