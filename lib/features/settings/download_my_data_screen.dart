import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import 'widgets/settings_list/settings_list.dart';

/// Request a copy of your data (handled via support until automated export ships).
class DownloadMyDataScreen extends StatelessWidget {
  const DownloadMyDataScreen({super.key});

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      queryParameters: {
        'subject': 'Data download request',
        'body':
            'Please process my data download request for my Afropeep account.\n\nUser ID / email: \n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Download my data',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Text(
            'You can request a copy of the personal data we hold about your account. '
            'Our team will verify your request and respond by email.',
            style: SettingsTextStyles.rowSubtitle(context),
          ),
          const SizedBox(height: 20),
          SettingsRow(
            title: 'Email support',
            subtitle: AppConfig.supportEmail,
            onTap: _emailSupport,
          ),
        ],
      ),
    );
  }
}
