import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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
      dev.log('Requesting contact permission');

      final status = await Permission.contacts.status;

      if (status.isGranted) {
        dev.log('Contact permission already granted');
        return true;
      }

      if (status.isDenied) {
        dev.log('Contact permission denied, requesting...');
        final result = await Permission.contacts.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        dev.log('Contact permission permanently denied');
        return false;
      }

      return false;
    } on Object catch (e) {
      dev.log('Error requesting contact permission: $e');
      return false;
    }
  }

  /// Get phone contacts with proper error handling.
  Future<List<Contact>> getPhoneContacts() async {
    try {
      dev.log('Getting phone contacts');

      final hasPermission = await requestContactPermission();
      if (!hasPermission) {
        dev.log('No contact permission');
        return [];
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      dev.log('Retrieved ${contacts.length} contacts');
      return contacts;
    } on Object catch (e) {
      dev.log('Error getting contacts: $e');
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
      if (query.isEmpty) return getPhoneContacts();

      final contacts = await getPhoneContacts();
      final lowercaseQuery = query.toLowerCase();

      return contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final phones =
            contact.phones.map((p) => p.number.toLowerCase()).join(' ');

        return name.contains(lowercaseQuery) || phones.contains(lowercaseQuery);
      }).toList();
    } on Object catch (e) {
      dev.log('Error searching contacts: $e');
      return [];
    }
  }

  /// Format contact for display
  String formatContactDisplay(Contact contact) {
    final name =
        contact.displayName.isNotEmpty ? contact.displayName : 'Unknown';
    final phone =
        contact.phones.isNotEmpty ? contact.phones.first.number : null;

    if (phone != null) {
      return '$name ($phone)';
    }
    return name;
  }

  /// Get primary phone number from contact
  String? getPrimaryPhone(Contact contact) {
    if (contact.phones.isEmpty) return null;
    return contact.phones.first.number;
  }

  /// Get primary email from contact
  String? getPrimaryEmail(Contact contact) {
    if (contact.emails.isEmpty) return null;
    return contact.emails.first.address;
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
      'contactName':
          contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
      'phone': phone,
      'email': email,
      'groupName': groupName,
      'groupId': groupId,
      'message': customMessage ?? 'You are invited to join "$groupName" group!',
      'invitationType': phone != null ? 'phone' : 'email',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Opens the device SMS composer with a pre-filled invitation message.
  Future<bool> sendSMSInvitation({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final uri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: <String, String>{'body': message},
      );
      return await _launchExternal(uri);
    } on Object catch (e) {
      dev.log('Error sending SMS: $e');
      return false;
    }
  }

  /// Opens the device email composer with a pre-filled invitation.
  Future<bool> sendEmailInvitation({
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: <String, String>{
          'subject': subject,
          'body': message,
        },
      );
      return await _launchExternal(uri);
    } on Object catch (e) {
      dev.log('Error sending email: $e');
      return false;
    }
  }

  Future<bool> _launchExternal(Uri uri) async {
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      return launched;
    } on Object catch (e) {
      dev.log('Error launching invitation URI: $e');
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
