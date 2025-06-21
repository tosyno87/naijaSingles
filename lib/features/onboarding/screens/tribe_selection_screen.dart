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
  String? _selectedTribe;
  final TextEditingController _otherTribeController = TextEditingController();
  bool _showOtherField = false;

  // Afropeep MVP theme colors
  static const Color backgroundColor = Color(0xFFFDF0E7);
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  // List of main Nigerian tribes for dropdown
  final List<String> _mainTribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Ijaw',
    'Kanuri',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
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
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description text
          Text(
            "This helps us connect you with people from similar backgrounds",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textLightBrown,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Dropdown for tribe selection
          Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedTribe != null ? afropeepGreen : Colors.transparent,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTribe,
                hint: Text(
                  "Select your tribe",
                  style: GoogleFonts.poppins(
                    color: textLightBrown,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: afropeepGreen),
                dropdownColor: cardBackground,
                style: GoogleFonts.poppins(
                  color: textDarkBrown,
                  fontSize: 16,
                ),
                items: _mainTribes.map((String tribe) {
                  return DropdownMenuItem<String>(
                    value: tribe,
                    child: Text(tribe),
                  );
                }).toList(),
                onChanged: _selectTribe,
              ),
            ),
          ),
          
          // Other tribe input field (conditionally shown)
          if (_showOtherField) ...[
            const SizedBox(height: 24),
            
            Text(
              "Please specify your tribe",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textDarkBrown,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _otherTribeController,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: "Enter your tribe",
                hintStyle: GoogleFonts.poppins(
                  color: textLightBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: afropeepGreen, width: 2),
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
}
