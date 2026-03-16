import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../../config/app_config.dart';

/// Native in-app Privacy Policy screen for auth and legal entry points.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Information we collect',
              body:
                  'We collect information you provide when you sign up, create a profile, or use the service, including name, email or phone, photos, preferences, and messages. We also collect device and usage data to operate and improve the service.',
            ),
            _Section(
              title: 'How we use data',
              body:
                  'We use your data to provide, personalize, and improve ${AppConfig.appName}, to communicate with you, to enforce our terms and policies, and to protect safety and security. We may use aggregated or anonymized data for analytics and product development.',
            ),
            _Section(
              title: 'Authentication data',
              body:
                  'When you sign in with phone or Google, we receive identifiers needed to create and secure your account. We do not receive or store your social account password. Authentication data is used only for sign-in and account linking.',
            ),
            _Section(
              title: 'Location, profile, photos, and messages',
              body:
                  'If you grant permission, we collect location data to show you nearby users and events. Profile and photo data are used to display your profile to other users and to moderate content. Messages are stored and processed to deliver chat and to enforce our policies.',
            ),
            _Section(
              title: 'Sharing and disclosure',
              body:
                  'We do not sell your personal information. We may share data with service providers who assist in operating the service, when required by law, or to protect rights and safety. We may share limited information with other users as part of the service (e.g. profile visibility).',
            ),
            _Section(
              title: 'Data retention',
              body:
                  'We retain your data for as long as your account is active or as needed to provide the service and comply with legal obligations. When you delete your account, we delete or anonymize your data in accordance with our retention policy.',
            ),
            _Section(
              title: 'Account deletion',
              body:
                  'You may delete your account at any time through account settings. Deletion removes your profile and associated data from the service. Some data may be retained where required by law or for legitimate business purposes (e.g. fraud prevention).',
            ),
            _Section(
              title: 'Security',
              body:
                  'We use industry-standard measures to protect your data, including encryption in transit and at rest, access controls, and secure authentication. No system is completely secure; we encourage you to use a strong password and to protect your account.',
            ),
            _Section(
              title: 'Contact',
              body:
                  'For privacy questions or requests, contact us at ${AppConfig.supportEmail}.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
