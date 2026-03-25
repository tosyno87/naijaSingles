import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class EnhancedBioScreen extends StatefulWidget {
  const EnhancedBioScreen({super.key});

  @override
  State<EnhancedBioScreen> createState() => _EnhancedBioScreenState();
}

class _EnhancedBioScreenState extends State<EnhancedBioScreen> {
  final TextEditingController _bioController = TextEditingController();
  static const int _maxLength = 300;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data != null && data.bio.isNotEmpty) {
        _bioController.text = data.bio;
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell your story', style: OnboardingTheme.titleStyle),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'A great bio helps you stand out. Keep it genuine.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: OnboardingTheme.subtitleToField),
              TextField(
                controller: _bioController,
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                style: OnboardingTheme.fieldTextStyle.copyWith(height: 1.5),
                maxLines: 8,
                maxLength: _maxLength,
                decoration: OnboardingTheme.fieldDecoration(
                  hint: 'Tell people about yourself...',
                ).copyWith(
                  counterStyle: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: OnboardingTheme.subtitleColor,
                  ),
                ),
                onChanged: (value) {
                  context
                      .read<OnboardingBloc>()
                      .add(OnboardingBioUpdated(value));
                },
              ),
              const SizedBox(height: OnboardingTheme.fieldToBottom),
            ],
          ),
        ),
      );
}
