import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ios_height_picker.dart';

/// Enhanced height input widget with iOS-style picker option
class EnhancedHeightInput extends StatefulWidget {
  // Toggle between iOS picker and text input

  const EnhancedHeightInput({
    required this.initialHeight,
    required this.initialUnit,
    required this.onChanged,
    super.key,
    this.useIOSPicker = true, // Default to iOS picker
  });
  final double initialHeight;
  final String initialUnit;
  final Function(double height, String unit) onChanged;
  final bool useIOSPicker;

  @override
  State<EnhancedHeightInput> createState() => _EnhancedHeightInputState();
}

class _EnhancedHeightInputState extends State<EnhancedHeightInput> {
  late double _height;
  late String _heightUnit;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight;
    _heightUnit = widget.initialUnit;
  }

  String _getHeightDisplay() {
    if (_heightUnit == 'cm') {
      return '${_height.round()} cm';
    } else {
      final double totalInches = _height / 2.54;
      final int feet = (totalInches / 12).floor();
      final int inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    }
  }

  void _showHeightPicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Color(0xFFFDF1E7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 16 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      'Select Height',
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onChanged(_height, _heightUnit);
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF008037),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // iOS Height Picker
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 20),
                  child: IOSHeightPicker(
                    initialHeight: _height,
                    initialUnit: _heightUnit,
                    onChanged: (height, unit) {
                      setState(() {
                        _height = height;
                        _heightUnit = unit;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useIOSPicker) {
      return _buildPickerButton();
    } else {
      return _buildTextInput();
    }
  }

  Widget _buildPickerButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Height selection labelLarge
        GestureDetector(
          onTap: _showHeightPicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Height',
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getHeightDisplay(),
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Tap to change',
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 14 : 12,
                        color: const Color(0xFF008037),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isTablet ? 16 : 14,
                      color: const Color(0xFF008037),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Helper text
        Text(
          'Tap above to select your height with an easy-to-use picker',
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    late TextEditingController controller;

    void updateController() {
      if (_heightUnit == 'cm') {
        controller = TextEditingController(text: _height.round().toString());
      } else {
        final double totalInches = _height / 2.54;
        final int feet = (totalInches / 12).floor();
        final int inches = (totalInches % 12).round();
        controller = TextEditingController(text: "$feet'$inches");
      }
    }

    updateController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit toggle
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _heightUnit = 'cm';
                    updateController();
                  });
                  widget.onChanged(_height, _heightUnit);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _heightUnit == 'cm'
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
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _heightUnit == 'cm' ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _heightUnit = 'ft';
                    updateController();
                  });
                  widget.onChanged(_height, _heightUnit);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: _heightUnit == 'ft'
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
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color:
                          _heightUnit == 'ft' ? Colors.white : Colors.black54,
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
          controller: controller,
          keyboardType: TextInputType.text,
          onChanged: (value) {
            if (_heightUnit == 'cm') {
              final height = double.tryParse(value);
              if (height != null && height >= 100 && height <= 250) {
                _height = height;
                widget.onChanged(_height, _heightUnit);
              }
            } else {
              final regex = RegExp(r"(\d+)'(\d+)");
              final match = regex.firstMatch(value);
              if (match != null) {
                final feet = int.tryParse(match.group(1) ?? '0') ?? 0;
                final inches = int.tryParse(match.group(2) ?? '0') ?? 0;
                if (feet >= 3 && feet <= 8 && inches >= 0 && inches < 12) {
                  _height = ((feet * 12) + inches) * 2.54;
                  widget.onChanged(_height, _heightUnit);
                }
              }
            }
          },
          decoration: InputDecoration(
            hintText: _heightUnit == 'cm' ? 'e.g., 170' : "e.g., 5'10",
            hintStyle: GoogleFonts.montserrat(
              color: Colors.grey.shade500,
              fontSize: isTablet ? 16 : 14,
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
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 20 : 16,
            ),
          ),
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 16 : 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
