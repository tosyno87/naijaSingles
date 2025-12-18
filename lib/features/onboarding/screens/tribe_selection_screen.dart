import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class TribeSelectionScreen extends StatefulWidget {
  const TribeSelectionScreen({super.key});

  @override
  State<TribeSelectionScreen> createState() => _TribeSelectionScreenState();
}

class _TribeSelectionScreenState extends State<TribeSelectionScreen> {
  String? _selectedNationality;
  String? _selectedTribe;
  final TextEditingController _otherTribeController = TextEditingController();
  bool _showOtherField = false;

  // Afropeep MVP theme colors
  static const Color backgroundColor = Colors.white;
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  // List of African nationalities
  final List<String> _nationalities = [
    'Nigeria',
    'Ghana',
    'Kenya',
    'South Africa',
    'Ethiopia',
    'Tanzania',
    'Uganda',
    'Zimbabwe',
    'Senegal',
    'Cameroon',
    'Ivory Coast',
    'Morocco',
    'Egypt',
    'Tunisia',
    'Algeria',
    'Sudan',
    'Mozambique',
    'Angola',
    'Madagascar',
    'Mali',
    'Burkina Faso',
    'Niger',
    'Malawi',
    'Zambia',
    'Somalia',
    'Guinea',
    'Benin',
    'Burundi',
    'Togo',
    'Eritrea',
    'Sierra Leone',
    'Libya',
    'Rwanda',
    'Chad',
    'Central African Republic',
    'Mauritania',
    'Namibia',
    'Botswana',
    'Gabon',
    'Gambia',
    'Lesotho',
    'Guinea-Bissau',
    'Equatorial Guinea',
    'Mauritius',
    'Eswatini',
    'Djibouti',
    'Comoros',
    'Cabo Verde',
    'São Tomé and Príncipe',
    'Seychelles',
    'African Diaspora',
    'Other',
  ];

  // List of main Nigerian tribes for dropdown (optional)
  final List<String> _mainTribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Ijaw',
    'Kanuri',
    'Ibibio',
    'Tiv',
    'Edo',
    'Urhobo',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<OnboardingController>(context, listen: false);

      // Load nationality
      if (controller.nationality != null && controller.nationality!.isNotEmpty) {
        setState(() {
          _selectedNationality = controller.nationality;
        });
      }

      // Load tribe (optional)
      if (controller.tribe.isNotEmpty) {
        if (_mainTribes.contains(controller.tribe)) {
          setState(() {
            _selectedTribe = controller.tribe;
          });
        } else {
          setState(() {
            _selectedTribe = 'Other';
            _otherTribeController.text = controller.tribe;
            _showOtherField = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _otherTribeController.dispose();
    super.dispose();
  }

  void _selectNationality(String? nationality) {
    setState(() {
      _selectedNationality = nationality;
    });
    if (nationality != null) {
      final controller =
          Provider.of<OnboardingController>(context, listen: false);
      final isDiaspora = nationality == 'African Diaspora';
      controller.updateNationality(nationality, isDiaspora);
    }
  }

  void _selectTribe(String? tribe) {
    setState(() {
      _selectedTribe = tribe;
      _showOtherField = tribe == 'Other';

      if (tribe != 'Other') {
        // Save to controller if not "Other"
        if (tribe != null) {
          Provider.of<OnboardingController>(context, listen: false)
              .setTribe(tribe);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          Text(
            'This helps us connect you with people from similar backgrounds',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textLightBrown,
            ),
          ),

          const SizedBox(height: 32),

          // Nationality field (required)
          Text(
            'Nationality *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDarkBrown,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedNationality != null
                    ? afropeepGreen
                    : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedNationality,
                hint: Text(
                  'Select your nationality',
                  style: GoogleFonts.montserrat(
                    color: textLightBrown,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: afropeepGreen),
                dropdownColor: cardBackground,
                style: GoogleFonts.montserrat(
                  color: textDarkBrown,
                  fontSize: 16,
                ),
                items: _nationalities
                    .map((String nationality) => DropdownMenuItem<String>(
                          value: nationality,
                          child: Text(nationality),
                        ))
                    .toList(),
                onChanged: _selectNationality,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Tribe field (optional)
          Row(
            children: [
              Text(
                'Tribe or Ethnic Group',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textDarkBrown,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(Optional)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: textLightBrown,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _selectedTribe != null ? afropeepGreen : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTribe,
                hint: Text(
                  'Select your tribe (optional)',
                  style: GoogleFonts.montserrat(
                    color: textLightBrown,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: afropeepGreen),
                dropdownColor: cardBackground,
                style: GoogleFonts.montserrat(
                  color: textDarkBrown,
                  fontSize: 16,
                ),
                items: _mainTribes.map((String tribe) => DropdownMenuItem<String>(
                    value: tribe,
                    child: Text(tribe),
                  ),).toList(),
                onChanged: _selectTribe,
              ),
            ),
          ),

          // Other tribe input field (conditionally shown)
          if (_showOtherField) ...[
            const SizedBox(height: 24),
            Text(
              'Please specify your tribe',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textDarkBrown,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherTribeController,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: 'Enter your tribe',
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
                if (value.trim().isNotEmpty) {
                  Provider.of<OnboardingController>(context, listen: false)
                      .setTribe(value.trim());
                }
              },
            ),
          ],
        ],
      ),
    );
}
