"use strict";
/**
 * NaijaSingles Cloud Functions - TypeScript Implementation
 *
 * This file exports all Cloud Functions for the NaijaSingles application.
 * The functions are organized into modular handlers for better maintainability.
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
exports.seedMatchTuningConfig = exports.healthCheck = exports.verifySubscriptionPurchase = exports.deleteAccountDirect = exports.confirmDeletionAfterPhoneProof = exports.confirmDeletionOtp = exports.startDeletionOtp = exports.onAuthUserDeleted = exports.aggregateMetrics = exports.validateIngestion = exports.createTestUsers = exports.onUserWritten = exports.onLikeCreated = exports.onSuperLikeCreated = exports.onMessageSent = exports.onMatchCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const matchHandlers_1 = require("./handlers/matchHandlers");
const messageHandlers_1 = require("./handlers/messageHandlers");
const likeHandlers_1 = require("./handlers/likeHandlers");
const testUserHandlers_1 = require("./handlers/testUserHandlers");
const discoverabilityHandlers_1 = require("./handlers/discoverabilityHandlers");
const matchQualityHandlers_1 = require("./handlers/matchQualityHandlers");
Object.defineProperty(exports, "validateIngestion", { enumerable: true, get: function () { return matchQualityHandlers_1.validateIngestion; } });
Object.defineProperty(exports, "aggregateMetrics", { enumerable: true, get: function () { return matchQualityHandlers_1.aggregateMetrics; } });
const authCleanupHandlers_1 = require("./handlers/authCleanupHandlers");
Object.defineProperty(exports, "onAuthUserDeleted", { enumerable: true, get: function () { return authCleanupHandlers_1.onAuthUserDeleted; } });
const accountDeletionCallables_1 = require("./handlers/accountDeletionCallables");
Object.defineProperty(exports, "confirmDeletionAfterPhoneProof", { enumerable: true, get: function () { return accountDeletionCallables_1.confirmDeletionAfterPhoneProof; } });
Object.defineProperty(exports, "confirmDeletionOtp", { enumerable: true, get: function () { return accountDeletionCallables_1.confirmDeletionOtp; } });
Object.defineProperty(exports, "deleteAccountDirect", { enumerable: true, get: function () { return accountDeletionCallables_1.deleteAccountDirect; } });
Object.defineProperty(exports, "startDeletionOtp", { enumerable: true, get: function () { return accountDeletionCallables_1.startDeletionOtp; } });
const subscriptionVerificationHandlers_1 = require("./handlers/subscriptionVerificationHandlers");
Object.defineProperty(exports, "verifySubscriptionPurchase", { enumerable: true, get: function () { return subscriptionVerificationHandlers_1.verifySubscriptionPurchase; } });
admin.initializeApp();
const matchHandlers = new matchHandlers_1.MatchHandlers();
const messageHandlers = new messageHandlers_1.MessageHandlers();
const likeHandlers = new likeHandlers_1.LikeHandlers();
const testUserHandlers = new testUserHandlers_1.TestUserHandlers();
const discoverabilityHandlers = new discoverabilityHandlers_1.DiscoverabilityHandlers();
exports.onMatchCreated = matchHandlers.onMatchCreated;
exports.onMessageSent = messageHandlers.onMessageSent;
exports.onSuperLikeCreated = likeHandlers.onSuperLikeCreated;
exports.onLikeCreated = likeHandlers.onLikeCreated;
exports.onUserWritten = discoverabilityHandlers.onUserWritten;
const isTestEnvEnabled = process.env.ENABLE_TEST_ENDPOINTS === 'true';
exports.createTestUsers = isTestEnvEnabled
    ? testUserHandlers.createTestUsers
    : (0, https_1.onRequest)((req, res) => {
        res.status(404).json({ error: 'Not available in production' });
    });
exports.healthCheck = (0, https_1.onRequest)((req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
    });
});
exports.seedMatchTuningConfig = (0, https_1.onRequest)(async (req, res) => {
    var _a;
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    const force = ((_a = req.body) === null || _a === void 0 ? void 0 : _a.force) === true;
    const db = admin.firestore();
    const docRef = db.collection('runtimeConfig').doc('matchTuning');
    if (!force) {
        const existing = await docRef.get();
        if (existing.exists) {
            res.status(200).json({ status: 'skipped', reason: 'document already exists' });
            return;
        }
    }
    const payload = {
        version: '1.0.0',
        rollbackKey: 'v0_defaults',
        datingWeights: { age: 0.30, location: 0.25, lifestyle: 0.20, interest: 0.15, completeness: 0.10 },
        friendshipWeights: { social: 0.35, interest: 0.25, location: 0.20, age: 0.10, completeness: 0.10 },
        networkingWeights: { professional: 0.40, industry: 0.25, location: 0.20, completeness: 0.15 },
        locationPerfectMiles: 5.0,
        locationDecayMiles: 50.0,
        locationFloorScore: 0.2,
        experiment: { active: false },
    };
    await docRef.set({ payload, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
    res.status(200).json({ status: 'seeded', version: payload.version });
});
//# sourceMappingURL=index.js.map