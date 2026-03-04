import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/widgets/custom_snackbar.dart';
import '../bloc/onboarding_bloc.dart';

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

  // Gender options for dropdown
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
    'Other',
  ];

  // Afropeep MVP theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data != null) {
        if (data.fullName.isNotEmpty) _nameController.text = data.fullName;

        if (data.dateOfBirth != null) {
          _selectedDate = data.dateOfBirth;
          _formatDateIntoController();
        }

        if (data.gender.isNotEmpty) _selectedGender = data.gender;
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
          colorScheme: const ColorScheme.light(
            primary: afropeepGreen,
            surface: cardBackground,
            onSurface: textDarkBrown,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: afropeepGreen,
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

      // Calculate age
      final today = DateTime.now();
      int age = today.year - picked.year;
      if (today.month < picked.month ||
          (today.month == picked.month && today.day < picked.day)) {
        age--;
      }

      if (!context.mounted) return;

      // Check if user is at least 18
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
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name section
            Text(
              "What's your name?",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: 'Enter your full name',
                hintStyle: GoogleFonts.montserrat(
                  color: textLightBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: afropeepGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                context.read<OnboardingBloc>().add(
                      OnboardingFullNameUpdated(value),
                    );
              },
            ),

            const SizedBox(height: 32),

            // Date of birth section
            Text(
              'When were you born?',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),

            const SizedBox(height: 12),

            // Date of birth field - Fixed to be read-only with proper icon
            TextField(
              controller: _dobController,
              readOnly: true, // Make it read-only
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: 'Select your date of birth',
                hintStyle: GoogleFonts.montserrat(
                  color: textLightBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: afropeepGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: afropeepGreen, // Ensure icon is visible
                  size: 24,
                ),
              ),
              onTap: () => _selectDate(context), // Open date picker on tap
            ),

            if (_selectedDate != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  builder: (context, state) => Text(
                    'Age: ${state.data?.age ?? 0}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: afropeepGreen,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Gender section
            Text(
              "What's your gender?",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textDarkBrown,
              ),
            ),

            const SizedBox(height: 12),

            // Gender dropdown with MVP styling
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedGender.isEmpty ? null : _selectedGender,
                hint: Text(
                  'Select your gender',
                  style: GoogleFonts.montserrat(
                    color: textLightBrown,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: afropeepGreen,
                ),
                dropdownColor: cardBackground,
                items: _genderOptions
                    .map(
                      (String gender) => DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: textDarkBrown,
                            fontWeight: FontWeight.w500,
                          ),
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
          ],
        ),
      );
}
