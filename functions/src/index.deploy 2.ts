/**
 * Temporary deployment index - exports only createTestUsers
 * This allows deploying only the new function without affecting existing ones
 */

import * as admin from 'firebase-admin';
import {TestUserHandlers} from './handlers/testUserHandlers';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize handlers
const testUserHandlers = new TestUserHandlers();

// Export only the new function
export const createTestUsers = testUserHandlers.createTestUsers;
