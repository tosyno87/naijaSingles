import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../common/widgets/custom_snackbar.dart';
import '../../user/controllers/onboarding_controller.dart';

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

  // Afropeep MVP theme colors
  static const Color backgroundColor = Color(0xFFFDF0E7);
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
      if (controller.fullName.isNotEmpty) {
        _nameController.text = controller.fullName;
      }
      
      if (controller.dateOfBirth != null) {
        _selectedDate = controller.dateOfBirth;
        _formatDateIntoController();
      }
      
      if (controller.gender.isNotEmpty) {
        _selectedGender = controller.gender;
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
      _dobController.text = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: afropeepGreen,
              onPrimary: Colors.white,
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
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
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
      
      // Check if user is at least 18
      if (age < 18) {
        CustomSnackbar.showSnackBarSimple(
          "You must be at least 18 years old to use this app",
          context,
        );
      } else {
        // Save to controller
        Provider.of<OnboardingController>(context, listen: false)
            .setDateOfBirth(picked);
      }
    }
  }

  void _selectGender(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    
    // Save to controller
    final controller = Provider.of<OnboardingController>(context, listen: false);
    print('🔍 BasicInfoScreen: Setting gender to "$gender"');
    print('🔍 Controller instance: ${controller.hashCode}');
    controller.setGender(gender);
    print('🔍 Controller gender after setting: "${controller.gender}"');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name section
          Text(
            "What's your name?",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDarkBrown,
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _nameController,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textDarkBrown,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: cardBackground,
              hintText: "Enter your full name",
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
              final controller = Provider.of<OnboardingController>(context, listen: false);
              print('🔍 BasicInfoScreen: Setting name to "$value"');
              print('🔍 Controller instance: ${controller.hashCode}');
              controller.setFullName(value);
              print('🔍 Controller name after setting: "${controller.fullName}"');
            },
          ),
          
          const SizedBox(height: 32),
          
          // Date of birth section
          Text(
            "When were you born?",
            style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textDarkBrown,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: cardBackground,
              hintText: "Select your date of birth",
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
              suffixIcon: Icon(
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
              child: Text(
                "Age: ${Provider.of<OnboardingController>(context).age}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: afropeepGreen,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Gender section
          Text(
            "What's your gender?",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textDarkBrown,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  label: "Male",
                  icon: Icons.male,
                  isSelected: _selectedGender == "Male",
                  onTap: () => _selectGender("Male"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption(
                  label: "Female",
                  icon: Icons.female,
                  isSelected: _selectedGender == "Female",
                  onTap: () => _selectGender("Female"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? afropeepGreen : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? afropeepGreen : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : afropeepGreen,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : textDarkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
