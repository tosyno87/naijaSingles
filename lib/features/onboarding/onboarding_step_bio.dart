import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import 'bloc/onboarding_bloc.dart';

/// Bio Info step of onboarding focusing on personal details.
///
/// This screen collects basic information about the user including
/// full name, age, location, and a short bio.
class OnboardingStepBio extends StatefulWidget {
  const OnboardingStepBio({
    required this.onNext,
    super.key,
    this.backgroundColor = AppColors.backgroundColor,
  });
  final VoidCallback onNext;
  final Color backgroundColor;

  @override
  State<OnboardingStepBio> createState() => _OnboardingStepBioState();
}

class _OnboardingStepBioState extends State<OnboardingStepBio> {
  // Keys for accessibility and testing
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _bioKey = GlobalKey();
  final GlobalKey _continueButtonKey = GlobalKey();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Form validation
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  // Age range for picker
  final List<int> _ageOptions =
      List.generate(63, (index) => index + 18); // 18-80
  int? _selectedAge;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;
      if (data != null) {
        if (data.userName != null) {
          _nameController.text = data.userName!;
        }
        if (data.dateOfBirth != null) {
          final now = DateTime.now();
          final age = now.year -
              data.dateOfBirth!.year -
              (now.month < data.dateOfBirth!.month ||
                      (now.month == data.dateOfBirth!.month &&
                          now.day < data.dateOfBirth!.day)
                  ? 1
                  : 0);
          _selectedAge = age;
        }
        if (data.locationName != null) {
          _locationController.text = data.locationName!;
        }
        _bioController.text = data.bio;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Show age picker modal
  void _showAgePickerModal(BuildContext context) {
    const Color deepGreen = Color(0xFF008037);

    unawaited(
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Your Age',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Age grid
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _ageOptions.length,
                    itemBuilder: (context, index) {
                      final age = _ageOptions[index];
                      final isSelected = _selectedAge == age;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAge = age;
                          });
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: isSelected ? deepGreen : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? deepGreen : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              age.toString(),
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Done labelLarge
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Validate all fields
  bool _validateFields() {
    // Check if form is valid
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Check if age is selected
    if (_selectedAge == null) {
      setState(() {
        _autoValidate = true;
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          // Deep green color for accents
          const Color deepGreen = Color(0xFF008037);

          return Scaffold(
            backgroundColor: widget.backgroundColor,
            body: SafeArea(
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress indicator
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: deepGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Step 1 of 4',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: deepGreen,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Header
                      Text(
                        'Tell us about yourself',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                        ),
                        semanticsLabel: 'Tell us about yourself, Step 1 of 4',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Let\'s start with some basic information to set up your profile.',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: Colors.brown.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  color: deepGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Full Name',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: _nameKey,
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.montserrat(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'e.g. Oluwaseun Johnson',
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                labelStyle: GoogleFonts.montserrat(
                                  color: deepGreen,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: deepGreen,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.red[400]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Age field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cake,
                                  color: deepGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Age',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Age field with custom picker
                            InkWell(
                              onTap: () => _showAgePickerModal(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cake,
                                      color: deepGreen,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Age',
                                            style: GoogleFonts.montserrat(
                                              color: deepGreen,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            _selectedAge != null
                                                ? _selectedAge.toString()
                                                : 'Select your age',
                                            style: GoogleFonts.montserrat(
                                              color: _selectedAge != null
                                                  ? Colors.black87
                                                  : Colors.grey[600],
                                              fontSize: 16,
                                              fontWeight: _selectedAge != null
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_selectedAge == null && _autoValidate)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, left: 16),
                                child: Text(
                                  'Please select your age',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.red[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Location field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: deepGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Location',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: _locationKey,
                              controller: _locationController,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.montserrat(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'City, Country',
                                hintText: 'e.g. Lagos, Nigeria',
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                labelStyle: GoogleFonts.montserrat(
                                  color: deepGreen,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: deepGreen,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.red[400]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.my_location,
                                    color: deepGreen,
                                  ),
                                  onPressed: () {
                                    // Location picker functionality would go here
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Location detection coming soon!',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your location';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bio field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: deepGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'About You',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Write a short bio to introduce yourself',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: _bioKey,
                              controller: _bioController,
                              textInputAction: TextInputAction.done,
                              style: GoogleFonts.montserrat(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Tell others about yourself, your interests, and what you\'re looking for...',
                                hintStyle: GoogleFonts.montserrat(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[400]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: deepGreen,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.red[400]!),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              maxLines: 5,
                              minLines: 3,
                              maxLength: 300,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please write a short bio';
                                }
                                if (value.trim().length < 10) {
                                  return 'Bio should be at least 10 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Continue labelLarge
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 56,
                          child: ElevatedButton(
                            key: _continueButtonKey,
                            onPressed: () {
                              // Validate form
                              if (_validateFields()) {
                                final bloc = context.read<OnboardingBloc>();
                                bloc.add(
                                  OnboardingFullNameUpdated(
                                    _nameController.text.trim(),
                                  ),
                                );

                                if (_selectedAge != null) {
                                  final now = DateTime.now();
                                  final dob = DateTime(
                                    now.year - _selectedAge!,
                                    now.month,
                                    now.day,
                                  );
                                  bloc.add(OnboardingDateOfBirthUpdated(dob));
                                }

                                bloc.add(
                                  OnboardingLocationUpdated(
                                    0,
                                    0,
                                    _locationController.text.trim(),
                                  ),
                                );

                                bloc.add(
                                  OnboardingBioUpdated(
                                    _bioController.text.trim(),
                                  ),
                                );

                                // Proceed to next step
                                unawaited(HapticFeedback.mediumImpact());
                                widget.onNext();
                              } else {
                                setState(() {
                                  _autoValidate = true;
                                });

                                unawaited(HapticFeedback.vibrate());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deepGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}
