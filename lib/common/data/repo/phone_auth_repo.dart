import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../config/app_config.dart';

import '../../../models/user_model.dart';
import '../../../services/secure_storage_service.dart';
import '../../constants/constants.dart';

class PhoneAuthRepository {
  FirebaseAuth auth = firebaseAuthInstance;

  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    // Normal flow for all phone numbers in production
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      timeout: const Duration(seconds: 120),
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> updatePhone({
    required String phoneNumber,
    required PhoneAuthCredential verificationCompleted,
  }) async {
    final User? user = firebaseAuthInstance.currentUser;

    if (user != null) {
      try {
        await user.updatePhoneNumber(verificationCompleted);
      } catch (e) {
        rethrow;
      }
    }
  }

  // sign out
  Future<void> signOut() async {
    // Clear secure storage before signing out
    try {
      final secureStorage = SecureStorageService();
      await secureStorage.clearAuthData();
      log('✅ Secure storage cleared on sign out');
    } catch (e) {
      log('⚠️ Error clearing secure storage on sign out: $e');
      // Continue with sign out even if secure storage clear fails
    }
    await auth.signOut();
  }

  // check signIn
  Future<bool> isSignedIn() async {
    final currentUser = auth.currentUser;
    return currentUser != null;
  }

  Future<void> deleteUser(User user) async {
    // user.delete();
    final checkedSnapshot = await firebaseFireStoreInstance
        .collection('users')
        .doc(user.uid)
        .collection('CheckedUser')
        .get();
    for (final element in checkedSnapshot.docs) {
      await firebaseFireStoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('CheckedUser')
          .doc(element.id)
          .delete();
      log('success');
    }
    final likedBySnapshot = await firebaseFireStoreInstance
        .collection('users')
        .doc(user.uid)
        .collection('LikedBy')
        .get();
    for (final element in likedBySnapshot.docs) {
      await firebaseFireStoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('LikedBy')
          .doc(element.id)
          .delete();
      log('success');
    }

    final matchesSnapshot = await firebaseFireStoreInstance
        .collection('users')
        .doc(user.uid)
        .collection('Matches')
        .get();
    for (final element in matchesSnapshot.docs) {
      await firebaseFireStoreInstance
          .collection('users')
          .doc(user.uid)
          .collection('Matches')
          .doc(element.id)
          .delete();
      log('success');
    }

    await firebaseFireStoreInstance.collection('users').doc(user.uid).delete();
    // Delete user details from Firebase Storage
    await deleteUserStorageCollection(user.uid);
  }

  // get current user
  Future<User?> getCurrentUser() async => auth.currentUser;

  Future<String?> getToken() async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        log('Cannot get token: No user is signed in');
        return null;
      }

      final token = await user.getIdToken(true); // Force refresh the token

      // Store token securely for offline use
      if (token != null) {
        try {
          final secureStorage = SecureStorageService();
          await secureStorage.storeAuthToken(token);
          await secureStorage.storeUserId(user.uid);
          log('✅ Token stored securely');
        } catch (e) {
          log('⚠️ Error storing token securely: $e');
          // Continue even if secure storage fails
        }
      }

      return token;
    } catch (e) {
      log('Error getting token: $e');
      return null;
    }
  }

  /// Get cached token from secure storage (for offline use)
  /// Returns null if no cached token exists
  Future<String?> getCachedToken() async {
    try {
      final secureStorage = SecureStorageService();
      return await secureStorage.getAuthToken();
    } catch (e) {
      log('Error getting cached token: $e');
      return null;
    }
  }

  /// Normalizes phone to digits-only so "+2348012345678" and "2348012345678" match.
  static String _normalizePhoneToDigits(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  Future<UserModel> registration({
    required Map<String, dynamic> userData,
  }) async {
    final User? user = auth.currentUser;
    final rawPhone = user!.phoneNumber ?? '';
    final phoneDigits = _normalizePhoneToDigits(rawPhone);

    userData.addAll({
      'userId': user.uid,
      'isBlocked': false,
      'isPremium': false,
      'phoneNumber': phoneDigits.isNotEmpty ? phoneDigits : rawPhone,
      'Pictures': [], // Initialize empty Pictures array
    });

    await firebaseFireStoreInstance
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
    final result = await firebaseFireStoreInstance
        .collection('users')
        .where('userId', isEqualTo: user.uid)
        .get();
    return UserModel.fromDocument(result.docs.first);
  }

  /// Returns the userId (document id) if an active user already has this phone number, null otherwise.
  /// Used to prevent duplicate account creation with the same phone number.
  /// Compares using digits-only so "+234..." and "234..." are treated the same; queries both
  /// digits-only and E.164 format for backward compatibility with existing documents.
  Future<String?> findUserIdByPhoneNumber(String phoneNumber) async {
    final digits = _normalizePhoneToDigits(phoneNumber);
    if (digits.isEmpty) return null;
    try {
      // Query digits-only (new format) and E.164 (legacy) so we match all stored formats.
      final snapshotDigits = await firebaseFireStoreInstance
          .collection('users')
          .where('phoneNumber', isEqualTo: digits)
          .limit(1)
          .get();
      if (snapshotDigits.docs.isNotEmpty) {
        final doc = snapshotDigits.docs.first;
        final data = doc.data();
        if (data['accountDeleted'] == true) return null;
        return doc.id;
      }
      final snapshotE164 = await firebaseFireStoreInstance
          .collection('users')
          .where('phoneNumber', isEqualTo: '+$digits')
          .limit(1)
          .get();
      if (snapshotE164.docs.isEmpty) return null;
      final doc = snapshotE164.docs.first;
      final data = doc.data();
      if (data['accountDeleted'] == true) return null;
      return doc.id;
    } catch (e) {
      log('❌ Error finding user by phone: $e');
      rethrow;
    }
  }

  Future<bool> userDetails(String userId) async {
    try {
      // Try direct document access first (faster and more reliable)
      final docSnapshot =
          await firebaseFireStoreInstance.collection('users').doc(userId).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data();
        log('✅ User document exists for: $userId');
        log('📄 User data keys: ${userData?.keys.toList()}');

        // Check if user has completed onboarding or has basic profile data
        // A user is considered registered if they have ANY of these indicators:
        final bool hasBasicProfile = userData != null &&
            (userData.containsKey('name') ||
                userData.containsKey('onboardingCompleted') ||
                userData.containsKey('profileSetupComplete') ||
                userData.containsKey('location') ||
                userData.containsKey('photos') ||
                userData.containsKey('Pictures'));

        if (hasBasicProfile) {
          log('✅ User has profile data - considered registered');
          return true;
        } else {
          log('⚠️ User document exists but has no profile data yet');
          // Still return true if document exists - they're registered even if onboarding incomplete
          return true;
        }
      } else {
        log('❌ User document does not exist for: $userId');
        return false;
      }
    } catch (e) {
      log('❌ Error checking user details: $e');
      // Fallback to query method
      try {
        final querySnapshot = await firebaseFireStoreInstance
            .collection('users')
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          log('✅ User found via query fallback');
          return true;
        }
      } catch (queryError) {
        log('❌ Query fallback also failed: $queryError');
      }
      return false;
    }
  }

  Future<UserModel> getRegisterUser() async {
    final User? fbuser = auth.currentUser;
    if (fbuser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      log('🔍 Fetching user data for: ${fbuser.uid}');

      // Try direct document access first (faster and more reliable)
      final docSnapshot = await firebaseFireStoreInstance
          .collection('users')
          .doc(fbuser.uid)
          .get();

      if (docSnapshot.exists) {
        log('✅ User document found via direct access');
        try {
          final registeredUser = UserModel.fromDocument(docSnapshot);
          return registeredUser;
        } catch (parseError) {
          log('❌ Error parsing user document: $parseError');
          // Fallback to query method
        }
      } else {
        log('⚠️ User document not found via direct access, trying query...');
      }

      // Fallback to query method
      final result = await firebaseFireStoreInstance
          .collection('users')
          .where('userId', isEqualTo: fbuser.uid)
          .get();

      if (result.docs.isEmpty) {
        log('❌ No user document found in query result');
        throw Exception('User document not found in Firestore');
      }

      log('✅ User document found via query (${result.docs.length} results)');
      final registeredUser = UserModel.fromDocument(result.docs.first);
      return registeredUser;
    } catch (e) {
      log('❌ Error in getRegisterUser: $e');
      rethrow;
    }
  }

  Future<void> deleteUserStorageCollection(String userId) async {
    try {
      log('🗑️ Starting storage deletion for user: $userId');

      // Initialize Firebase Storage
      final FirebaseStorage storage =
          FirebaseStorage.instanceFor(bucket: bucketId);

      // Get a reference to the user's collection
      final Reference userCollectionRef = storage.ref().child('users/$userId');

      try {
        // List all the files in the user's collection
        final ListResult listResult = await userCollectionRef.listAll();
        log('📁 Found ${listResult.items.length} files to delete');

        // Delete each file in the user's collection
        for (Reference item in listResult.items) {
          try {
            await item.delete();
            log('✅ Deleted file: ${item.fullPath}');
          } catch (fileError) {
            log('⚠️ Error deleting file ${item.fullPath}: $fileError');
            // Continue with other files even if one fails
          }
        }

        // Note: Firebase Storage doesn't have folders - deleting all files is sufficient
        // The "folder" will automatically disappear when empty
        log('✅ Storage cleanup completed for user: $userId');
      } catch (listError) {
        // If listAll fails (e.g., path doesn't exist), that's okay
        log('⚠️ Could not list files (path may not exist): $listError');
        // This is non-fatal - user might not have uploaded files
      }
    } catch (error) {
      // Log error but don't throw - storage cleanup failure shouldn't block account deletion
      log('⚠️ Error during storage deletion (non-fatal): $error');
      log('⚠️ Error type: ${error.runtimeType}');
      if (error is FirebaseException) {
        log('⚠️ Firebase Storage error: code=${error.code}, message=${error.message}');
      }
      // Don't rethrow - allow account deletion to continue even if storage cleanup fails
    }
  }
}
