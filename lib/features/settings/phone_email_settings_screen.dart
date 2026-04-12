import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/routes/route_name.dart';
import '../auth/email/email_auth_service.dart';
import 'widgets/settings_list/settings_list.dart';

/// Phone number and email management.
class PhoneEmailSettingsScreen extends StatelessWidget {
  const PhoneEmailSettingsScreen({super.key});

  String _maskPhone(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not set';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return raw;
    return '••••${digits.substring(digits.length - 4)}';
  }

  Future<void> _openUpdatePhone(BuildContext context) async {
    final userModel = context.read<UserBloc>().currentUser;
    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to update your phone number.')),
      );
      return;
    }
    await Navigator.pushNamed(
      context,
      RouteName.updatePhoneScreen,
      arguments: userModel,
    );
  }

  Future<void> _promptChangeEmail(BuildContext context) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final controller = TextEditingController(text: authUser.email ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Change email',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'New email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Send link',
              style: GoogleFonts.montserrat(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    final next = controller.text.trim();
    if (next.isEmpty) return;

    try {
      await EmailAuthService().updateEmail(next);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Check $next to verify your new email.',
              style: GoogleFonts.montserrat(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final phone = authUser?.phoneNumber;
    final email = authUser?.email ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Phone & Email',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SettingsSection(
            title: 'Contact',
            children: [
              SettingsRow(
                title: 'Phone number',
                subtitle: _maskPhone(phone),
                onTap: () => unawaited(_openUpdatePhone(context)),
              ),
              Divider(height: 1, color: Colors.grey.shade300),
              SettingsRow(
                title: 'Email',
                subtitle: email.isEmpty ? 'Not set' : email,
                onTap: email.isEmpty
                    ? null
                    : () => unawaited(_promptChangeEmail(context)),
              ),
            ],
          ),
          if (email.isEmpty)
            Padding(
              padding: AppSpacing.pagePadding,
              child: Text(
                'Email changes use your sign-in provider. Add an email from Connected accounts if needed.',
                style: SettingsTextStyles.consequence(context),
              ),
            ),
        ],
      ),
    );
  }
}
