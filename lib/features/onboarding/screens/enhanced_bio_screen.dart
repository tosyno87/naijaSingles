import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class EnhancedBioScreen extends StatefulWidget {
  const EnhancedBioScreen({super.key});

  @override
  State<EnhancedBioScreen> createState() => _EnhancedBioScreenState();
}

class _EnhancedBioScreenState extends State<EnhancedBioScreen> {
  final TextEditingController _bioController = TextEditingController();
  final int _maxLength = 500; // Tinder standard

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<OnboardingController>(context, listen: false);

      if (controller.bio.isNotEmpty) {
        _bioController.text = controller.bio;
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF008037);
    const Color textColor = Color(0xFF333333);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Minimal like Tinder
          Text(
            'Tell your story',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),

          const SizedBox(height: 32),

          // Bio Text Field - Simple like Tinder
          TextField(
            controller: _bioController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textColor,
              height: 1.5,
            ),
            maxLines: 10,
            maxLength: _maxLength,
            decoration: InputDecoration(
              hintText: "Tell people about yourself...",
              hintStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(20),
              counterStyle: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            onChanged: (value) {
              // Save to controller
              Provider.of<OnboardingController>(context, listen: false)
                  .setBio(value);
            },
          ),
        ],
      ),
    );
  }
}
