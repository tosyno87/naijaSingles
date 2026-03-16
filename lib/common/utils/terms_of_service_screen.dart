import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_config.dart';
import '../constants/app_colors.dart';

/// Native in-app Terms of Service screen for auth and legal entry points.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
            'Terms of Service',
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
                title: 'Acceptance of terms',
                body:
                    'By creating an account or using ${AppConfig.appName}, you agree to these Terms of Service. If you do not agree, do not use the service.',
              ),
              _Section(
                title: 'Eligibility',
                body:
                    'You must be at least 18 years old and legally able to enter into a binding agreement to use this service. By using ${AppConfig.appName}, you represent that you meet these requirements.',
              ),
              _Section(
                title: 'Account responsibilities',
                body:
                    'You are responsible for maintaining the confidentiality of your account and for all activity under your account. You must provide accurate information and keep it up to date.',
              ),
              _Section(
                title: 'Community behavior',
                body:
                    'You agree to treat other users with respect and to comply with our community guidelines. Harassment, hate speech, impersonation, and other prohibited conduct may result in account suspension or removal.',
              ),
              _Section(
                title: 'Content and messaging',
                body:
                    'You retain ownership of content you post. You grant ${AppConfig.appName} a license to use, display, and distribute your content as needed to operate the service. You are responsible for the content you share and must not post illegal or infringing material.',
              ),
              _Section(
                title: 'Payments and subscriptions',
                body:
                    'If you purchase a subscription or other paid feature, additional terms and payment policies apply. Refunds are subject to our refund policy and applicable law.',
              ),
              _Section(
                title: 'Account suspension or removal',
                body:
                    'We may suspend or terminate your account if you breach these terms, violate our policies, or for other operational or legal reasons. You may delete your account at any time through account settings.',
              ),
              _Section(
                title: 'Disclaimer and liability',
                body:
                    'The service is provided "as is." To the extent permitted by law, we disclaim warranties and limit our liability. We are not liable for indirect, incidental, or consequential damages arising from your use of the service.',
              ),
              _Section(
                title: 'Contact',
                body:
                    'For questions about these Terms of Service, contact us at ${AppConfig.supportEmail}.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
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
