import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/constants/app_colors.dart';
import 'afrocentric_height_picker.dart';

/// Afrocentric height input widget with inline scroll picker
class AfrocentricHeightInput extends StatefulWidget {

  const AfrocentricHeightInput({
    required this.initialHeight, required this.initialUnit, required this.onChanged, super.key,
  });
  final double initialHeight;
  final String initialUnit;
  final Function(double height, String unit) onChanged;

  @override
  State<AfrocentricHeightInput> createState() => _AfrocentricHeightInputState();
}

class _AfrocentricHeightInputState extends State<AfrocentricHeightInput> {
  late double _height;
  late String _heightUnit;
  bool _isExpanded = false;

  // MVP Colors
  static const Color backgroundColor =
      Color(0xFFF7E8DA); // Card background from MVP
  static const Color primaryGreen =
      Color(0xFF008037); // MVP green
  static const Color textDarkBrown = Color(0xFF3A1D0F); // Dark text from MVP
  static const Color textLightBrown = Color(0xFF8B6C59); // Light text from MVP
  static const Color creamBackground = AppColors.backgroundColor; // Main background

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

  String _getEquivalentDisplay() {
    if (_heightUnit == 'cm') {
      final double totalInches = _height / 2.54;
      final int feet = (totalInches / 12).floor();
      final int inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    } else {
      return '${_height.round()} cm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable height display card
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded
                    ? primaryGreen
                    : primaryGreen.withValues(alpha: 0.3),
                width: _isExpanded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Height icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.height,
                    color: primaryGreen,
                    size: isTablet ? 24 : 20,
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 12),

                // Height info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Height',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                          color: textLightBrown,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Row(
                        children: [
                          Text(
                            _getHeightDisplay(),
                            style: GoogleFonts.montserrat(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: textDarkBrown,
                            ),
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            '(${_getEquivalentDisplay()})',
                            style: GoogleFonts.montserrat(
                              fontSize: isTablet ? 14 : 12,
                              color: textLightBrown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand/collapse indicator
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: primaryGreen,
                    size: isTablet ? 28 : 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable picker section
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? null : 0,
          child: _isExpanded
              ? Container(
                  margin: EdgeInsets.only(top: isTablet ? 16 : 12),
                  child: AfrocentricHeightPicker(
                    initialHeight: _height,
                    initialUnit: _heightUnit,
                    onChanged: (height, unit) {
                      setState(() {
                        _height = height;
                        _heightUnit = unit;
                      });
                      widget.onChanged(height, unit);
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Helper text when collapsed
        if (!_isExpanded) ...[
          SizedBox(height: isTablet ? 8 : 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app,
                size: isTablet ? 16 : 14,
                color: textLightBrown,
              ),
              SizedBox(width: isTablet ? 6 : 4),
              Text(
                'Tap above to change your height',
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 12 : 10,
                  color: textLightBrown,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
