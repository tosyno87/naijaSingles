import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable selection option widget for onboarding screens
class SelectionOption extends StatelessWidget {
  const SelectionOption({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
    super.key,
    this.icon,
    this.isFullWidth = true,
  });
  final String label;
  final String value;
  final String selectedValue;
  final Function(String) onSelected;
  final IconData? icon;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? 24 : 16,
          vertical: screenWidth > 600 ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withValues(alpha: 0.1)
              : Colors.white,
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
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color:
                    isSelected ? const Color(0xFF008037) : Colors.grey.shade600,
                size: screenWidth > 600 ? 24 : 20,
              ),
              SizedBox(width: screenWidth > 600 ? 16 : 12),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: screenWidth > 600 ? 18 : 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF008037) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF008037),
                size: screenWidth > 600 ? 24 : 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable section header widget
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.subtitle,
  });
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: screenWidth > 600 ? 22 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: screenWidth > 600 ? 8 : 4),
          Text(
            subtitle!,
            style: GoogleFonts.montserrat(
              fontSize: screenWidth > 600 ? 16 : 14,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}

/// Height input widget with unit toggle
class HeightInput extends StatefulWidget {
  const HeightInput({
    required this.initialHeight,
    required this.initialUnit,
    required this.onChanged,
    super.key,
  });
  final double initialHeight;
  final String initialUnit;
  final Function(double height, String unit) onChanged;

  @override
  State<HeightInput> createState() => _HeightInputState();
}

class _HeightInputState extends State<HeightInput> {
  late TextEditingController _controller;
  late String _selectedUnit;
  late double _height;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    _height = widget.initialHeight;
    _updateController();
  }

  void _updateController() {
    if (_selectedUnit == 'cm') {
      _controller = TextEditingController(text: _height.round().toString());
    } else {
      // Convert cm to feet and inches
      final double totalInches = _height / 2.54;
      final int feet = (totalInches / 12).floor();
      final int inches = (totalInches % 12).round();
      _controller = TextEditingController(text: '$feet\'$inches"');
    }
  }

  void _onUnitChanged(String unit) {
    setState(() {
      if (_selectedUnit != unit) {
        _selectedUnit = unit;
        _updateController();
        widget.onChanged(_height, _selectedUnit);
      }
    });
  }

  void _onHeightChanged(String value) {
    if (_selectedUnit == 'cm') {
      final height = double.tryParse(value);
      if (height != null && height >= 100 && height <= 250) {
        _height = height;
        widget.onChanged(_height, _selectedUnit);
      }
    } else {
      // Parse feet and inches format (e.g., "5'10"")
      final regex = RegExp(r"(\d+)'(\d+)");
      final match = regex.firstMatch(value);
      if (match != null) {
        final feet = int.tryParse(match.group(1) ?? '0') ?? 0;
        final inches = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (feet >= 3 && feet <= 8 && inches >= 0 && inches < 12) {
          _height = ((feet * 12) + inches) * 2.54; // Convert to cm
          widget.onChanged(_height, _selectedUnit);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit toggle
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onUnitChanged('cm'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenWidth > 600 ? 16 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedUnit == 'cm'
                        ? const Color(0xFF008037)
                        : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'cm',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _selectedUnit == 'cm' ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _onUnitChanged('ft'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenWidth > 600 ? 16 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedUnit == 'ft'
                        ? const Color(0xFF008037)
                        : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ft/in',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: screenWidth > 600 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _selectedUnit == 'ft' ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Height input
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.text,
          onChanged: _onHeightChanged,
          decoration: InputDecoration(
            hintText: _selectedUnit == 'cm' ? 'e.g., 170' : "e.g., 5'10",
            hintStyle: GoogleFonts.montserrat(
              color: Colors.grey.shade500,
              fontSize: screenWidth > 600 ? 16 : 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 20 : 16,
              vertical: screenWidth > 600 ? 20 : 16,
            ),
          ),
          style: GoogleFonts.montserrat(
            fontSize: screenWidth > 600 ? 16 : 14,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        // Display current height in both units
        Text(
          _selectedUnit == 'cm'
              ? 'Height: ${_height.round()} cm (${_convertToFeetInches(_height)})'
              : 'Height: ${_convertToFeetInches(_height)} (${_height.round()} cm)',
          style: GoogleFonts.montserrat(
            fontSize: screenWidth > 600 ? 14 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _convertToFeetInches(double cm) {
    final double totalInches = cm / 2.54;
    final int feet = (totalInches / 12).floor();
    final int inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Reusable continue labelLarge
class ContinueButton extends StatelessWidget {
  const ContinueButton({
    required this.onPressed,
    super.key,
    this.text = 'Continue',
    this.isEnabled = true,
  });
  final VoidCallback onPressed;
  final String text;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: screenWidth > 600 ? 64 : 56,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFF008037) : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: screenWidth > 600 ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
