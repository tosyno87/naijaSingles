import 'dart:async';
import 'dart:developer' as dev;

import 'package:contacts_service/contacts_service.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Industry-standard contact invitation service
/// Features:
/// - Phone contact access with permission handling
/// - Email invitation system
/// - Contact validation and formatting
/// - Privacy-compliant contact handling
class ContactInvitationService {
  factory ContactInvitationService() => _instance;
  ContactInvitationService._internal();
  static final ContactInvitationService _instance =
      ContactInvitationService._internal();

  /// Check and request contact permission
  Future<bool> requestContactPermission() async {
    try {
      dev.log('📱 Requesting contact permission');

      final status = await Permission.contacts.status;

      if (status.isGranted) {
        dev.log('✅ Contact permission already granted');
        return true;
      }

      if (status.isDenied) {
        dev.log('🔒 Contact permission denied, requesting...');
        final result = await Permission.contacts.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        dev.log('❌ Contact permission permanently denied');
        return false;
      }

      return false;
    } on Object catch (e) {
      dev.log('❌ Error requesting contact permission: $e');
      return false;
    }
  }

  /// Get phone contacts with proper error handling.
  Future<List<Contact>> getPhoneContacts() async {
    try {
      dev.log('📞 Getting phone contacts');

      final hasPermission = await requestContactPermission();
      if (!hasPermission) {
        dev.log('❌ No contact permission');
        return [];
      }

      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
        photoHighResolution: false,
      );

      dev.log('📱 Retrieved ${contacts.length} contacts');
      return contacts;
    } on Object catch (e) {
      dev.log('❌ Error getting contacts: $e');
      return [];
    }
  }

  /// Check whether contact permission is currently granted without requesting.
  Future<bool> isContactPermissionGranted() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  /// Whether the user has permanently denied contact access.
  Future<bool> isContactPermissionPermanentlyDenied() async {
    final status = await Permission.contacts.status;
    return status.isPermanentlyDenied;
  }

  /// Search contacts by name or phone
  Future<List<Contact>> searchContacts(String query) async {
    try {
      if (query.isEmpty) return await getPhoneContacts();

      final contacts = await getPhoneContacts();
      final lowercaseQuery = query.toLowerCase();

      return contacts.where((contact) {
        final name = contact.displayName?.toLowerCase() ?? '';
        final phones = contact.phones
                ?.map((p) => p.value?.toLowerCase() ?? '')
                .join(' ') ??
            '';

        return name.contains(lowercaseQuery) || phones.contains(lowercaseQuery);
      }).toList();
    } on Object catch (e) {
      dev.log('❌ Error searching contacts: $e');
      return [];
    }
  }

  /// Validate email address
  bool isValidEmail(String email) => EmailValidator.validate(email);

  /// Format contact for display
  String formatContactDisplay(Contact contact) {
    final name = contact.displayName ?? 'Unknown';
    final phone = contact.phones?.isNotEmpty ?? false
        ? contact.phones!.first.value
        : null;

    if (phone != null) {
      return '$name ($phone)';
    }
    return name;
  }

  /// Get primary phone number from contact
  String? getPrimaryPhone(Contact contact) {
    if (contact.phones?.isEmpty ?? false) return null;

    // Return the first phone number
    return contact.phones!.first.value;
  }

  /// Get primary email from contact
  String? getPrimaryEmail(Contact contact) {
    if (contact.emails?.isEmpty ?? false) return null;

    // Return the first email
    return contact.emails!.first.value;
  }

  /// Create invitation data for a contact
  Map<String, dynamic> createInvitationData({
    required Contact contact,
    required String groupName,
    required String groupId,
    String? customMessage,
  }) {
    final phone = getPrimaryPhone(contact);
    final email = getPrimaryEmail(contact);

    return {
      'contactName': contact.displayName ?? 'Unknown',
      'phone': phone,
      'email': email,
      'groupName': groupName,
      'groupId': groupId,
      'message': customMessage ?? 'You are invited to join "$groupName" group!',
      'invitationType': phone != null ? 'phone' : 'email',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Send SMS invitation (placeholder - would integrate with SMS service)
  Future<bool> sendSMSInvitation({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      dev.log('📱 Sending SMS invitation to $phoneNumber');
      // In a real app, you'd integrate with an SMS service
      // For now, we'll just log the action
      dev.log('SMS Message: $message');
      return true;
    } on Object catch (e) {
      dev.log('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Send email invitation (placeholder - would integrate with email service)
  Future<bool> sendEmailInvitation({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      dev.log('📧 Sending email invitation to $email');
      // In a real app, you'd integrate with an email service
      // For now, we'll just log the action
      dev.log('Email Subject: $subject');
      dev.log('Email Message: $message');
      return true;
    } on Object catch (e) {
      dev.log('❌ Error sending email: $e');
      return false;
    }
  }

  /// Show permission denied dialog
  void showPermissionDeniedDialog(BuildContext context) {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'To add members from your contacts, please grant contact permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                unawaited(openAppSettings());
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
