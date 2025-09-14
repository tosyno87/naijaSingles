"use strict";
/**
 * Type definitions for NaijaSingles Cloud Functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationStatus = exports.NotificationType = void 0;
var NotificationType;
(function (NotificationType) {
    NotificationType["MATCH"] = "match";
    NotificationType["MESSAGE"] = "message";
    NotificationType["SUPER_LIKE"] = "super_like";
    NotificationType["LIKE"] = "like";
})(NotificationType || (exports.NotificationType = NotificationType = {}));
var NotificationStatus;
(function (NotificationStatus) {
    NotificationStatus["SENT"] = "sent";
    NotificationStatus["FAILED"] = "failed";
    NotificationStatus["STORED"] = "stored";
})(NotificationStatus || (exports.NotificationStatus = NotificationStatus = {}));
//# sourceMappingURL=index.js.map