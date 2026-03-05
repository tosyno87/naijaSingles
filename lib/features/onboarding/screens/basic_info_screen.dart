import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/custom_snackbar.dart';
import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedGender = '';

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data != null) {
        if (data.fullName.isNotEmpty) _nameController.text = data.fullName;

        if (data.dateOfBirth != null) {
          _selectedDate = data.dateOfBirth;
          _formatDateIntoController();
        }

        if (data.gender.isNotEmpty) {
          setState(() => _selectedGender = data.gender);
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _formatDateIntoController() {
    if (_selectedDate != null) {
      _dobController.text =
          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: OnboardingTheme.primaryGreen,
            surface: OnboardingTheme.fieldFill,
            onSurface: OnboardingTheme.sectionLabelColor,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: OnboardingTheme.primaryGreen,
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _formatDateIntoController();
      });

      final today = DateTime.now();
      int age = today.year - picked.year;
      if (today.month < picked.month ||
          (today.month == picked.month && today.day < picked.day)) {
        age--;
      }

      if (!context.mounted) return;

      if (age < 18) {
        CustomSnackbar.showSnackBarSimple(
          'You must be at least 18 years old to use this app',
          context,
        );
      } else {
        context.read<OnboardingBloc>().add(
              OnboardingDateOfBirthUpdated(picked),
            );
      }
    }
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    context.read<OnboardingBloc>().add(OnboardingGenderUpdated(gender));
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("What's your name?", style: OnboardingTheme.sectionLabelStyle),
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

              Text('When were you born?', style: OnboardingTheme.sectionLabelStyle),
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
                onTap: () => _selectDate(context),
              ),

              if (_selectedDate != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: BlocBuilder<OnboardingBloc, OnboardingState>(
                    builder: (context, state) => Text(
                      'Age: ${state.data?.age ?? 0}',
                      style: OnboardingTheme.helperStyle.copyWith(
                        color: OnboardingTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: OnboardingTheme.fieldToSection),

              Text("What's your gender?", style: OnboardingTheme.sectionLabelStyle),
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
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: OnboardingTheme.primaryGreen,
                    size: OnboardingTheme.fieldIconSize,
                  ),
                  dropdownColor: OnboardingTheme.fieldFill,
                  borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
                  items: _genderOptions
                      .map(
                        (String gender) => DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                            style: OnboardingTheme.fieldTextStyle,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _selectGender(newValue);
                    }
                  },
                ),
              ),

              const SizedBox(height: OnboardingTheme.fieldToBottom),
            ],
          ),
        ),
      );
}
