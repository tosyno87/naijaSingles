import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/settings_list/settings_list.dart';

/// Read-only list of linked sign-in providers (link/unlink flows can be added later).
class ConnectedAccountsSettingsScreen extends StatelessWidget {
  const ConnectedAccountsSettingsScreen({super.key});

  static String _labelForProvider(String id) {
    switch (id) {
      case 'google.com':
        return 'Google';
      case 'apple.com':
        return 'Apple';
      case 'phone':
        return 'Phone';
      case 'password':
        return 'Email & password';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData ?? [];

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
          'Connected accounts',
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
            title: 'Sign-in methods',
            consequence:
                'These are the ways you can sign in. Linking more providers helps you recover your account.',
            children: [
              if (providers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'No linked providers found.',
                    style: SettingsTextStyles.rowSubtitle(context),
                  ),
                )
              else
                ...providers.map((info) {
                  final label = _labelForProvider(info.providerId);
                  final detail = info.email ?? info.phoneNumber ?? info.uid;
                  final detailLine =
                      (detail != null && detail.isNotEmpty) ? detail : 'Connected';
                  return Column(
                    key: ValueKey(info.providerId),
                    children: [
                      SettingsRow(
                        title: label,
                        subtitle: detailLine,
                      ),
                      Divider(height: 1, color: Colors.grey.shade300),
                    ],
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
