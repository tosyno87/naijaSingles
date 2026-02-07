import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/onboarding_bloc.dart';

class BioScreen extends StatefulWidget {
  const BioScreen({super.key});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  final TextEditingController _bioController = TextEditingController();
  final int _maxLength = 300;
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;
      if (data != null && data.bio.isNotEmpty) {
        _bioController.text = data.bio;
        setState(() {
          _currentLength = data.bio.length;
        });
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
    // Define colors
    const Color primaryColor = Color(0xFF008037); // Deep Green
    const Color textColor = Color(0xFF333333);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Share a bit about who you are, what you enjoy, and what you're looking for",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 24),

          // Bio text field
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _bioController,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textColor,
              ),
              maxLines: 8,
              maxLength: _maxLength,
              decoration: InputDecoration(
                hintText: 'Write your bio here...',
                hintStyle: GoogleFonts.montserrat(
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
              onChanged: (value) {
                setState(() {
                  _currentLength = value.length;
                });

                context.read<OnboardingBloc>().add(OnboardingBioUpdated(value));
              },
            ),
          ),

          const SizedBox(height: 8),

          // Character counter
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$_currentLength/$_maxLength',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: _currentLength >= 20 ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Bio tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips for a great bio:',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTipItem(
                  'Be authentic and show your personality',
                ),
                _buildTipItem(
                  'Mention your interests and hobbies',
                ),
                _buildTipItem(
                  "Share what you're looking for in a partner",
                ),
                _buildTipItem(
                  'Add something unique about yourself',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.amber.shade800,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );
}
