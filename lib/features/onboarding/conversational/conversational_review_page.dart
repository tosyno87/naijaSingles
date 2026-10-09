import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/custom_snackbar.dart';
import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class ConversationalReviewPage extends StatefulWidget {
  const ConversationalReviewPage({
    required this.onContinue,
    required this.onSkipToForms,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkipToForms;

  @override
  State<ConversationalReviewPage> createState() =>
      _ConversationalReviewPageState();
}

class _ConversationalReviewPageState extends State<ConversationalReviewPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _bioController;
  late final TextEditingController _tribeController;
  DateTime? _selectedDate;
  String _selectedGender = '';
  String _lookingFor = 'Dating';

  static const _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
    'Other',
  ];

  static const _lookingForOptions = ['Dating', 'Friendship', 'Networking'];

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingBloc>().state.data;
    _nameController = TextEditingController(text: data?.fullName ?? '');
    _bioController = TextEditingController(text: data?.bio ?? '');
    _tribeController = TextEditingController(text: data?.tribe ?? '');
    _selectedDate = data?.dateOfBirth;
    _selectedGender = data?.gender ?? '';
    final looking = data?.lookingFor;
    _lookingFor =
        looking != null && looking.isNotEmpty ? looking : 'Dating';
    _dobController = TextEditingController();
    _formatDateIntoController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    _tribeController.dispose();
    super.dispose();
  }

  void _formatDateIntoController() {
    if (_selectedDate == null) {
      _dobController.clear();
      return;
    }
    _dobController.text =
        '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: OnboardingTheme.primaryGreen,
            surface: OnboardingTheme.fieldFill,
            onSurface: OnboardingTheme.sectionLabelColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final today = DateTime.now();
    var age = today.year - picked.year;
    if (today.month < picked.month ||
        (today.month == picked.month && today.day < picked.day)) {
      age--;
    }
    if (age < 18) {
      CustomSnackbar.showSnackBarSimple(
        'You must be at least 18 years old to use this app',
        context,
      );
      return;
    }
    setState(() {
      _selectedDate = picked;
      _formatDateIntoController();
    });
    context.read<OnboardingBloc>().add(OnboardingDateOfBirthUpdated(picked));
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check your draft', style: OnboardingTheme.titleStyle),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'Confirm your name, gender, and birthday. Edit anything the draft got wrong.',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: OnboardingTheme.subtitleToField),
              Text(
                "What's your name?",
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              TextField(
                controller: _nameController,
                style: OnboardingTheme.fieldTextStyle,
                decoration: OnboardingTheme.fieldDecoration(
                  hint: 'Enter your full name',
                ),
                onChanged: (value) {
                  context.read<OnboardingBloc>().add(
                        OnboardingFullNameUpdated(value),
                      );
                },
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text(
                'When were you born?',
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              TextField(
                controller: _dobController,
                readOnly: true,
                style: OnboardingTheme.fieldTextStyle,
                decoration: OnboardingTheme.fieldDecoration(
                  hint: 'Select your date of birth',
                  suffix: const Icon(
                    Icons.calendar_today,
                    color: OnboardingTheme.primaryGreen,
                    size: OnboardingTheme.fieldIconSize,
                  ),
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text(
                "What's your gender?",
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              Container(
                constraints: const BoxConstraints(
                  minHeight: OnboardingTheme.fieldHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: OnboardingTheme.fieldContentPadding,
                ),
                decoration: OnboardingTheme.dropdownDecoration(
                  hasFocus: _selectedGender.isNotEmpty,
                ),
                child: DropdownButton<String>(
                  value: _selectedGender.isEmpty ? null : _selectedGender,
                  hint: Text(
                    'Select your gender',
                    style: GoogleFonts.montserrat(
                      color: OnboardingTheme.subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _genderOptions
                      .map(
                        (gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(
                            gender,
                            style: OnboardingTheme.fieldTextStyle,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedGender = value);
                    context.read<OnboardingBloc>().add(
                          OnboardingGenderUpdated(value),
                        );
                  },
                ),
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text('About you', style: OnboardingTheme.sectionLabelStyle),
              const SizedBox(height: OnboardingTheme.labelToField),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                style: OnboardingTheme.fieldTextStyle,
                decoration: OnboardingTheme.fieldDecoration(
                  hint: 'A short bio in your own words',
                ),
                onChanged: (value) {
                  context
                      .read<OnboardingBloc>()
                      .add(OnboardingBioUpdated(value));
                },
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text(
                'Heritage / tribe',
                style: OnboardingTheme.sectionLabelStyle,
              ),
              const SizedBox(height: OnboardingTheme.labelToField),
              TextField(
                controller: _tribeController,
                style: OnboardingTheme.fieldTextStyle,
                decoration: OnboardingTheme.fieldDecoration(hint: 'Optional'),
                onChanged: (value) {
                  context
                      .read<OnboardingBloc>()
                      .add(OnboardingTribeUpdated(value));
                },
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              Text('I am here for', style: OnboardingTheme.sectionLabelStyle),
              const SizedBox(height: OnboardingTheme.labelToField),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in _lookingForOptions)
                    ChoiceChip(
                      label: Text(option),
                      selected: _lookingFor == option,
                      selectedColor: OnboardingTheme.fieldBorder,
                      onSelected: (_) {
                        setState(() => _lookingFor = option);
                        context.read<OnboardingBloc>().add(
                              OnboardingLookingForUpdated(option),
                            );
                      },
                    ),
                ],
              ),
              const SizedBox(height: OnboardingTheme.fieldToBottom),
              SizedBox(
                width: double.infinity,
                height: OnboardingTheme.buttonHeight,
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  builder: (context, state) {
                    final canContinue =
                        state.data?.isBasicInfoComplete ?? false;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:
                            canContinue ? OnboardingTheme.buttonGradient : null,
                        color: canContinue
                            ? null
                            : OnboardingTheme.primaryGreen
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.buttonRadius,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: canContinue ? widget.onContinue : null,
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
                        child: Text(
                          'Confirm and add photos',
                          style: OnboardingTheme.buttonTextStyle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: widget.onSkipToForms,
                child: Text(
                  'Fill it in myself',
                  style: GoogleFonts.montserrat(
                    color: OnboardingTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
