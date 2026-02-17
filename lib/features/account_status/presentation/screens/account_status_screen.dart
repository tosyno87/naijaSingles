import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../bloc/account_status_bloc.dart';
import '../bloc/account_status_event.dart';
import '../bloc/account_status_state.dart';

/// Screen that lets users pause their account or go incognito as a
/// non-destructive alternative to permanent account deletion.
class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_userId.isNotEmpty) {
      context.read<AccountStatusBloc>().add(LoadAccountStatus(_userId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Account Status',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: BlocConsumer<AccountStatusBloc, AccountStatusState>(
          listener: (context, state) {
            if (state is AccountStatusError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AccountStatusLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final currentStatus =
                state is AccountStatusLoaded ? state.status : 'active';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current status banner
                  _StatusBanner(status: currentStatus),
                  const SizedBox(height: 24),

                  // Explanation header
                  Text(
                    'Take a Break',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Need some time away? You can pause your profile or go incognito '
                    'without losing your matches and conversations.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Option cards
                  _StatusOptionCard(
                    icon: Icons.pause_circle_outline,
                    title: 'Pause Account',
                    subtitle: 'Your profile will be completely hidden from '
                        'discovery. No one can find or match with you. '
                        'Your existing matches and chats are preserved.',
                    isSelected: currentStatus == 'paused',
                    accentColor: const Color(0xFFFF9800),
                    onTap: currentStatus == 'paused'
                        ? null
                        : () => _confirmStatusChange(
                              context,
                              title: 'Pause Account?',
                              description:
                                  'Your profile will be hidden from all discovery and '
                                  'search results. Your existing matches and conversations '
                                  'will remain intact.\n\nYou can reactivate anytime.',
                              onConfirm: () {
                                context.read<AccountStatusBloc>().add(
                                      PauseAccount(userId: _userId),
                                    );
                              },
                            ),
                  ),
                  const SizedBox(height: 16),

                  _StatusOptionCard(
                    icon: Icons.visibility_off_outlined,
                    title: 'Go Incognito',
                    subtitle: 'Browse privately — you won\'t appear in anyone\'s '
                        'discovery feed. Your matches and conversations '
                        'remain accessible.',
                    isSelected: currentStatus == 'incognito',
                    accentColor: const Color(0xFF7C4DFF),
                    onTap: currentStatus == 'incognito'
                        ? null
                        : () => _confirmStatusChange(
                              context,
                              title: 'Go Incognito?',
                              description:
                                  'You\'ll become invisible in discovery and search. '
                                  'Your profile won\'t be shown to new people.\n\n'
                                  'Existing matches and conversations stay intact. '
                                  'You can turn this off anytime.',
                              onConfirm: () {
                                context.read<AccountStatusBloc>().add(
                                      EnableIncognito(userId: _userId),
                                    );
                              },
                            ),
                  ),
                  const SizedBox(height: 24),

                  // Reactivate button (shown only when not active)
                  if (currentStatus == 'paused' || currentStatus == 'incognito')
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<AccountStatusBloc>().add(
                                ReactivateAccount(userId: _userId),
                              );
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Reactivate My Profile',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'While paused or incognito:\n'
                            '• You won\'t appear in discovery or search\n'
                            '• No new matches will be created\n'
                            '• Existing matches & chats remain intact\n'
                            '• You can reactivate at any time',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      );

  void _confirmStatusChange(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        content: Text(
          description,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner showing the current account status with colour-coded indicator.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, Color fgColor, IconData icon, String label) =
        switch (status) {
      'paused' => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.pause_circle_filled,
          'Account Paused',
        ),
      'incognito' => (
          const Color(0xFFEDE7F6),
          const Color(0xFF4A148C),
          Icons.visibility_off,
          'Incognito Mode',
        ),
      _ => (
          const Color(0xFFE8F5E9),
          AppColors.primaryGreen,
          Icons.check_circle,
          'Active & Discoverable',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fgColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: fgColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for each status option (pause / incognito).
class _StatusOptionCard extends StatelessWidget {
  const _StatusOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Active',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSelected && onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      );
}
