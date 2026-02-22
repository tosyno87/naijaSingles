# Security Best Practices Report

## Executive Summary
This review focused on Firebase security rules and Cloud Functions in the Afropeep codebase. The most urgent issues are authorization gaps in Firestore rules that allow authenticated users to forge likes/matches, and a publicly reachable test-user creation endpoint with a hard-coded fallback secret. Several collections intended for system-only writes are also writable by any authenticated user. Addressing these will significantly reduce account abuse, data tampering, and privacy exposure.

## Critical Findings

**[C-1] Public test-user creation endpoint accepts a hard-coded fallback secret**
- **Impact:** If the admin secret is not configured, any attacker can call the endpoint with a known default token to create users and consume quotas, potentially disrupting production data integrity.
- **Evidence:** `functions/src/handlers/testUserHandlers.ts:82-86`
- **Why it matters:** Public HTTP Cloud Functions should fail closed unless an explicit, high-entropy secret is set. A default secret is effectively no secret in production.
- **Secure-by-default improvement:** Remove the default fallback and require `functions.config().admin.secret` (or a required env var) to be present; deny requests when missing. Consider restricting by IP allowlist or Firebase Auth custom claims for admin use.

## High Findings

**[H-1] Likes can be forged on behalf of other users**
- **Evidence:** `firestore.rules:153-157`
- **Issue:** `allow create` does not require `request.auth.uid == request.resource.data.from`.
- **Risk:** Any authenticated user can create likes between arbitrary users, manipulating matching logic and notifications.
- **Secure-by-default improvement:** Require `request.auth.uid == request.resource.data.from`, validate `from != to`, and validate schema with strict key allowlisting.

**[H-2] Matches can be created by any authenticated user without being a participant**
- **Evidence:** `firestore.rules:182-191`
- **Issue:** `allow create` only checks that `users` is present and size 2, but does not require the requester to be one of those users.
- **Risk:** Attackers can create matches between other users, forcing chats/notifications or creating unwanted relationships.
- **Secure-by-default improvement:** Require `request.auth.uid in request.resource.data.users` and validate `users.size() == 2` with uniqueness.

**[H-3] Legacy Likes collection is broadly readable and writable by any authenticated user**
- **Evidence:** `firestore.rules:174-179`
- **Issue:** Authenticated users can read/write any document in `/Likes`.
- **Risk:** Unauthorized data access and tampering with likes history.
- **Secure-by-default improvement:** Either remove legacy access or apply the same ownership constraints as `/likes` (and ensure `from` equals `request.auth.uid`).

## Medium Findings

**[M-1] Event moderation records are writable by any authenticated user**
- **Evidence:** `firestore.rules:451-459`
- **Issue:** `allow create, update: if request.auth != null`.
- **Risk:** Any user can approve/deny events or alter moderation status.
- **Secure-by-default improvement:** Restrict to admin users via custom claims (e.g., `request.auth.token.admin == true`) or move writes exclusively to Cloud Functions with Admin SDK.

**[M-2] Group unread counts can be updated by any authenticated user**
- **Evidence:** `firestore.rules:645-657`
- **Issue:** `allow update: if request.auth != null`.
- **Risk:** Users can tamper with other users’ unread counts, impacting UX and analytics.
- **Secure-by-default improvement:** Restrict updates to the owner (`request.auth.uid == resource.data.userId`) or system-only writes via Cloud Functions.

**[M-3] Usage tracking records can be created by any authenticated user**
- **Evidence:** `firestore.rules:133-150`
- **Issue:** `/superLikeUsage` and `/undoUsage` allow create without validating `userId`.
- **Risk:** Attackers can spoof usage records for other users, disrupting limits or analytics.
- **Secure-by-default improvement:** Require `request.resource.data.userId == request.auth.uid` and strict key validation.

**[M-4] Security logs are writable by any authenticated user**
- **Evidence:** `firestore.rules:679-682`
- **Issue:** `allow create` is open to any authenticated user.
- **Risk:** Log spam and tampering with security analytics.
- **Secure-by-default improvement:** Restrict to system-only writes (Admin SDK) or use an allowlist claim.

**[M-5] Group metadata is readable by any authenticated user**
- **Evidence:** `firestore.rules:463-466`, `firestore.rules:520-523`, `firestore.rules:547-553`
- **Issue:** `unifiedGroups`, `groups`, and `groupChats` allow read access to any authenticated user, regardless of membership.
- **Risk:** Information disclosure of private groups, members, or metadata.
- **Secure-by-default improvement:** Require membership for read access or maintain a minimal public listing collection separate from private group metadata.

## Low Findings

**[L-1] Storage rules allow any authenticated user to read profile photos**
- **Evidence:** `storage.rules:18-39`
- **Issue:** All authenticated users can read profile photos under `/profile_photos` and `/users`, regardless of profile privacy settings.
- **Risk:** If profiles can be private in Firestore, this leaks private user photos.
- **Secure-by-default improvement:** If privacy is required, store public photos in a separate path with read access and keep private photos owner-only, or gate access through Cloud Functions with signed URLs.

## Notes
- This repo includes Flutter/Dart code, but there were no Dart security best-practice reference docs available in the skill. The findings focus on Firebase rules and Cloud Functions, which are the primary security boundary in this codebase.

