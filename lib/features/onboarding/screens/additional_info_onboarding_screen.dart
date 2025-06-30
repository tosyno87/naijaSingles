import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';
import '../widgets/afropeep_height_dropdown.dart';

class AdditionalInfoOnboardingScreen extends StatefulWidget {
  const AdditionalInfoOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<AdditionalInfoOnboardingScreen> createState() => _AdditionalInfoOnboardingScreenState();
}

class _AdditionalInfoOnboardingScreenState extends State<AdditionalInfoOnboardingScreen> {
  String _heightFtIn = HeightData.defaultHeightFtIn;
  int _heightCm = HeightData.defaultHeightCm;
  String _lookingFor = 'Dating';
  String _relationshipIntent = 'Not sure yet';

  final List<Map<String, dynamic>> _lookingForOptions = [
    {'label': 'Dating', 'value': 'Dating', 'icon': Icons.favorite_outline},
    {'label': 'Friendship', 'value': 'Friendship', 'icon': Icons.people_outline},
    {'label': 'Networking', 'value': 'Networking', 'icon': Icons.business_center_outlined},
  ];

  final List<Map<String, dynamic>> _relationshipIntentOptions = [
    {'label': 'Short-term fun', 'value': 'Short-term', 'icon': Icons.flash_on_outlined},
    {'label': 'Long-term relationship', 'value': 'Long-term', 'icon': Icons.favorite_border},
    {'label': 'Casual dating', 'value': 'Casual', 'icon': Icons.coffee_outlined},
    {'label': 'Not sure yet', 'value': 'Not sure yet', 'icon': Icons.help_outline},
  ];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<OnboardingController>(context, listen: false);
    
    // Initialize height from controller if available
    if (controller.height > 0) {
      _heightCm = controller.height.round();
      // Try to find matching ft/in value
      String? ftIn = HeightData.getFtInFromCm(_heightCm);
      if (ftIn != null) {
        _heightFtIn = ftIn;
      }
    }
    
    _lookingFor = controller.lookingFor;
    _relationshipIntent = controller.relationshipIntent;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Tell us more about you',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Help us create better matches for you',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 18 : 16,
              color: Colors.black54,
            ),
          ),
          
          SizedBox(height: isTablet ? 48 : 40),
          
          // Height Section
          _buildSectionHeader('Height', 'Your height helps with better matching'),
          SizedBox(height: isTablet ? 20 : 16),
          AfropeepHeightDropdown(
            initialHeightFtIn: _heightFtIn,
            initialHeightCm: _heightCm,
            onChanged: (heightFtIn, heightCm) {
              setState(() {
                _heightFtIn = heightFtIn;
                _heightCm = heightCm;
              });
              // Save to controller
              final controller = Provider.of<OnboardingController>(context, listen: false);
              controller.setHeightFromDropdown(heightFtIn, heightCm);
            },
          ),
          
          SizedBox(height: isTablet ? 48 : 40),
          
          // Looking For Section
          _buildSectionHeader('I\'m looking for', 'What brings you to NaijaSingles?'),
          SizedBox(height: isTablet ? 20 : 16),
          ..._buildLookingForOptions(),
          
          SizedBox(height: isTablet ? 48 : 40),
          
          // Relationship Intent Section
          _buildSectionHeader('Relationship goals', 'What are you hoping to find?'),
          SizedBox(height: isTablet ? 20 : 16),
          ..._buildRelationshipIntentOptions(),
          
          SizedBox(height: isTablet ? 48 : 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLookingForOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return _lookingForOptions.map((option) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        child: _buildSelectionOption(
          option['label'],
          option['value'],
          _lookingFor,
          (value) {
            setState(() {
              _lookingFor = value;
            });
            // Save to controller
            final controller = Provider.of<OnboardingController>(context, listen: false);
            controller.setLookingFor(value);
          },
          option['icon'],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRelationshipIntentOptions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return _relationshipIntentOptions.map((option) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        child: _buildSelectionOption(
          option['label'],
          option['value'],
          _relationshipIntent,
          (value) {
            setState(() {
              _relationshipIntent = value;
            });
            // Save to controller
            final controller = Provider.of<OnboardingController>(context, listen: false);
            controller.setRelationshipIntent(value);
          },
          option['icon'],
        ),
      );
    }).toList();
  }

  Widget _buildSelectionOption(
    String label,
    String value,
    String selectedValue,
    Function(String) onSelected,
    IconData icon,
  ) {
    final isSelected = selectedValue == value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF008037).withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF008037) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF008037) : Colors.grey.shade600,
              size: isTablet ? 24 : 20,
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF008037) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF008037),
                size: isTablet ? 24 : 20,
              ),
          ],
        ),
      ),
    );
  }
}
