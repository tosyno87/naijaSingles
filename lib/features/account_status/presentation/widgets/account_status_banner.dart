import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/account_status_service.dart';

/// A persistent top banner that shows when the user's account is paused or
/// incognito. Tapping it navigates to the account status screen to reactivate.
///
/// Uses a Firestore stream so it reflects real-time changes.
class AccountStatusBanner extends StatelessWidget {
  const AccountStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final snapshotData = snapshot.data;
        if (!snapshot.hasData || snapshotData == null || !snapshotData.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshotData.data() as Map<String, dynamic>?;
        final status = data?['accountStatus'] as String? ?? 'active';

        if (status == 'active') return const SizedBox.shrink();

        final (Color bgColor, Color fgColor, IconData icon, String label) =
            switch (status) {
          'paused' => (
              const Color(0xFFFFF3E0),
              const Color(0xFFE65100),
              Icons.pause_circle_filled,
              'Your profile is paused',
            ),
          'incognito' => (
              const Color(0xFFEDE7F6),
              const Color(0xFF4A148C),
              Icons.visibility_off,
              'Incognito mode is on',
            ),
          _ => (
              Colors.grey.shade200,
              Colors.grey.shade700,
              Icons.info_outline,
              'Account status: $status',
            ),
        };

        return GestureDetector(
          onTap: () => _onTap(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              boxShadow: [
                BoxShadow(
                  color: fgColor.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Icon(icon, color: fgColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                  ),
                  _ReactivateChip(fgColor: fgColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    unawaited(AccountStatusService().reactivateAccount(userId: userId));
  }
}

class _ReactivateChip extends StatelessWidget {
  const _ReactivateChip({required this.fgColor});
  final Color fgColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Reactivate',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      );
}
