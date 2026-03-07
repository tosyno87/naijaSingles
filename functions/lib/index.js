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
exports.backfillDiscoverable = exports.healthCheck = exports.createTestUsers = exports.onUserWritten = exports.onLikeCreated = exports.onSuperLikeCreated = exports.onMessageSent = exports.onMatchCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const matchHandlers_1 = require("./handlers/matchHandlers");
const messageHandlers_1 = require("./handlers/messageHandlers");
const likeHandlers_1 = require("./handlers/likeHandlers");
const testUserHandlers_1 = require("./handlers/testUserHandlers");
const discoverabilityHandlers_1 = require("./handlers/discoverabilityHandlers");
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
// Temporary one-time backfill endpoint. Remove after running.
exports.backfillDiscoverable = (0, https_1.onRequest)(async (req, res) => {
    const db = admin.firestore();
    const batchSize = 500;
    let lastDoc;
    let totalUpdated = 0;
    let totalSkipped = 0;
    const compute = (data) => {
        var _a;
        const status = (_a = data.accountStatus) !== null && _a !== void 0 ? _a : 'active';
        if (status !== 'active')
            return false;
        if (data.isDeleted === true)
            return false;
        if (data.isProfilePrivate === true)
            return false;
        return true;
    };
    // eslint-disable-next-line no-constant-condition
    while (true) {
        let query = db.collection('users').orderBy('__name__').limit(batchSize);
        if (lastDoc)
            query = query.startAfter(lastDoc);
        const snapshot = await query.get();
        if (snapshot.empty)
            break;
        const batch = db.batch();
        let batchCount = 0;
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const computed = compute(data);
            if (data.isDiscoverable !== computed) {
                batch.update(doc.ref, { isDiscoverable: computed });
                batchCount++;
            }
        }
        if (batchCount > 0)
            await batch.commit();
        totalUpdated += batchCount;
        totalSkipped += snapshot.docs.length - batchCount;
        lastDoc = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.docs.length < batchSize)
            break;
    }
    res.status(200).json({
        status: 'complete',
        updated: totalUpdated,
        alreadyCorrect: totalSkipped,
    });
});
//# sourceMappingURL=index.js.map