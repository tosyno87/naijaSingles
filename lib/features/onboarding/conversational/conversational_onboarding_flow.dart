import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/routes/route_name.dart';
import '../../../common/widgets/state_views/app_loading_view.dart';
import '../bloc/onboarding_bloc.dart';
import '../data/onboarding_draft_mapper.dart';
import '../data/onboarding_profile_functions_service.dart';
import '../onboarding_theme.dart';
import '../screens/enhanced_photo_upload_screen.dart';
import '../screens/location_screen.dart';
import 'conversational_prompts_page.dart';
import 'conversational_review_page.dart';

enum ConversationalOnboardingStep {
  consent,
  prompts,
  extracting,
  review,
  photos,
  location,
}

/// Talk-or-type onboarding. Skip or extract errors land on the existing
/// 8-step [OnboardingMain] form via [RouteName.onboardingForms].
class ConversationalOnboardingFlow extends StatefulWidget {
  const ConversationalOnboardingFlow({
    super.key,
    this.functionsService,
    this.mapper = const OnboardingDraftMapper(),
  });

  final OnboardingProfileFunctionsService? functionsService;
  final OnboardingDraftMapper mapper;

  @override
  State<ConversationalOnboardingFlow> createState() =>
      _ConversationalOnboardingFlowState();
}

class _ConversationalOnboardingFlowState
    extends State<ConversationalOnboardingFlow> {
  ConversationalOnboardingStep _step = ConversationalOnboardingStep.consent;
  OnboardingProfileFunctionsService? _cachedFunctions;

  OnboardingProfileFunctionsService get _functions =>
      widget.functionsService ??
      (_cachedFunctions ??= OnboardingProfileFunctionsService());

  void _goToForms() {
    unawaited(
      Navigator.of(context).pushReplacementNamed(RouteName.onboardingForms),
    );
  }

  Future<void> _extract(List<PromptAnswerDraft> drafts) async {
    setState(() => _step = ConversationalOnboardingStep.extracting);
    try {
      final encoded = await encodePromptAnswers(drafts);
      final answers = encoded
          .map(
            (row) => OnboardingAnswerPayload(
              promptId: row['promptId'] as String,
              text: row['text'] as String?,
              audioBase64: row['audioBase64'] as String?,
              mimeType: row['mimeType'] as String?,
              durationMs: row['durationMs'] as int?,
            ),
          )
          .toList();
      final result = await _functions.extract(answers: answers);
      if (!mounted) return;
      final current = context.read<OnboardingBloc>().state.data;
      if (current == null) {
        _goToForms();
        return;
      }
      final drafted = widget.mapper.apply(
        current: current,
        fields: result.fields,
      );
      context.read<OnboardingBloc>().add(OnboardingDraftApplied(drafted));
      setState(() => _step = ConversationalOnboardingStep.review);
    } on OnboardingExtractException catch (e) {
      if (!mounted) return;
      if (e.shouldFallBackToForms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'resource-exhausted'
                  ? 'Drafting is paused right now. Continue with the form.'
                  : 'Could not draft your profile. Continue with the form.',
            ),
          ),
        );
        _goToForms();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _step = ConversationalOnboardingStep.prompts);
    } on Object catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not draft your profile. Continue with the form.'),
        ),
      );
      _goToForms();
    }
  }

  void _complete() {
    context.read<OnboardingBloc>().add(OnboardingSaveUserData(context));
  }

  String get _title => switch (_step) {
        ConversationalOnboardingStep.consent => 'Welcome',
        ConversationalOnboardingStep.prompts => 'About you',
        ConversationalOnboardingStep.extracting => 'Drafting',
        ConversationalOnboardingStep.review => 'Your draft',
        ConversationalOnboardingStep.photos => 'Photos',
        ConversationalOnboardingStep.location => 'Location',
      };

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: OnboardingTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _title,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: OnboardingTheme.primaryGreen,
          ),
        ),
        centerTitle: true,
      ),
      body: switch (_step) {
        ConversationalOnboardingStep.consent => _ConsentPage(
            onContinue: () =>
                setState(() => _step = ConversationalOnboardingStep.prompts),
            onSkipToForms: _goToForms,
          ),
        ConversationalOnboardingStep.prompts => ConversationalPromptsPage(
            onContinue: (drafts) => unawaited(_extract(drafts)),
            onSkipToForms: _goToForms,
          ),
        ConversationalOnboardingStep.extracting => const AppLoadingView(
            message: 'Drafting your profile from what you shared…',
          ),
        ConversationalOnboardingStep.review => ConversationalReviewPage(
            onContinue: () =>
                setState(() => _step = ConversationalOnboardingStep.photos),
            onSkipToForms: _goToForms,
          ),
        ConversationalOnboardingStep.photos => Column(
            children: [
              const Expanded(child: EnhancedPhotoUploadScreen()),
              _FooterButton(
                label: 'Next',
                bottomPadding: math.max(16, bottomSafe).toDouble(),
                enabled: context.select(
                  (OnboardingBloc bloc) =>
                      bloc.state.data?.isPhotoUploaded ?? false,
                ),
                onPressed: () => setState(
                  () => _step = ConversationalOnboardingStep.location,
                ),
              ),
            ],
          ),
        ConversationalOnboardingStep.location => Column(
            children: [
              const Expanded(child: LocationScreen()),
              _FooterButton(
                label: 'Finish',
                bottomPadding: math.max(16, bottomSafe).toDouble(),
                enabled: context.select((OnboardingBloc bloc) {
                  final name = bloc.state.data?.locationName;
                  return name != null && name.trim().isNotEmpty;
                }),
                onPressed: _complete,
              ),
            ],
          ),
      },
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.onContinue,
    required this.onSkipToForms,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkipToForms;

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: Padding(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us who you are', style: OnboardingTheme.titleStyle),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'Talk or type about yourself, what you are looking for, and your culture. We use those words to draft a Houston diaspora community profile. We do not keep the recording.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'You will still confirm your name, gender, and date of birth, then add photos and location. AfroPeep is for adults 18 and over.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: OnboardingTheme.buttonHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: OnboardingTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(
                      OnboardingTheme.buttonRadius,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      'Continue',
                      style: OnboardingTheme.buttonTextStyle,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: onSkipToForms,
                child: Text(
                  'Fill it in myself',
                  style: GoogleFonts.montserrat(
                    color: OnboardingTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: math.max(16, MediaQuery.paddingOf(context).bottom),
              ),
            ],
          ),
        ),
      );
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.bottomPadding,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          OnboardingTheme.horizontalPadding,
          16,
          OnboardingTheme.horizontalPadding,
          bottomPadding,
        ),
        child: SizedBox(
          width: double.infinity,
          height: OnboardingTheme.buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: enabled ? OnboardingTheme.buttonGradient : null,
              color: enabled
                  ? null
                  : OnboardingTheme.primaryGreen.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(OnboardingTheme.buttonRadius),
            ),
            child: ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    OnboardingTheme.buttonRadius,
                  ),
                ),
              ),
              child: Text(label, style: OnboardingTheme.buttonTextStyle),
            ),
          ),
        ),
      );
}
