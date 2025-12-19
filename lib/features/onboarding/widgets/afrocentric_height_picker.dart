import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/constants/app_colors.dart';

class AfrocentricHeightPicker extends StatefulWidget {
  const AfrocentricHeightPicker({
    required this.initialHeight,
    required this.initialUnit,
    required this.onChanged,
    super.key,
  });
  final double initialHeight; // Height in cm
  final String initialUnit; // 'cm' or 'ft'
  final Function(double height, String unit) onChanged;

  @override
  State<AfrocentricHeightPicker> createState() =>
      _AfrocentricHeightPickerState();
}

class _AfrocentricHeightPickerState extends State<AfrocentricHeightPicker> {
  late String _selectedUnit;
  late double _heightInCm;

  // For CM picker
  late FixedExtentScrollController _cmController;

  // For FT/IN picker
  late FixedExtentScrollController _feetController;
  late FixedExtentScrollController _inchesController;

  // Height ranges
  static const int minCm = 120; // 4 feet
  static const int maxCm = 220; // 7'2"
  static const int minFeet = 4;
  static const int maxFeet = 7;
  static const int maxInches = 11;

  // MVP Colors
  static const Color backgroundColor =
      Color(0xFFF7E8DA); // Card background from MVP
  static const Color primaryGreen = Color(0xFF008037); // MVP green
  static const Color textDarkBrown = Color(0xFF3A1D0F); // Dark text from MVP
  static const Color textLightBrown = Color(0xFF8B6C59); // Light text from MVP
  static const Color creamBackground =
      AppColors.backgroundColor; // Main background

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    _heightInCm = widget.initialHeight;

    _initializeControllers();
  }

  void _initializeControllers() {
    if (_selectedUnit == 'cm') {
      final int cmIndex = (_heightInCm.round() - minCm).clamp(0, maxCm - minCm);
      _cmController = FixedExtentScrollController(initialItem: cmIndex);
    } else {
      // Convert cm to feet and inches
      final double totalInches = _heightInCm / 2.54;
      final int feet = (totalInches / 12).floor().clamp(minFeet, maxFeet);
      final int inches = (totalInches % 12).round().clamp(0, maxInches);

      _feetController =
          FixedExtentScrollController(initialItem: feet - minFeet);
      _inchesController = FixedExtentScrollController(initialItem: inches);
    }
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _onUnitChanged(String unit) {
    if (_selectedUnit != unit) {
      setState(() {
        _selectedUnit = unit;
        _initializeControllers();
      });
      widget.onChanged(_heightInCm, _selectedUnit);
    }
  }

  void _onCmChanged(int index) {
    _heightInCm = (minCm + index).toDouble();
    widget.onChanged(_heightInCm, _selectedUnit);
  }

  void _onFeetInchesChanged() {
    final int feet = _feetController.selectedItem + minFeet;
    final int inches = _inchesController.selectedItem;
    _heightInCm = ((feet * 12) + inches) * 2.54;
    widget.onChanged(_heightInCm, _selectedUnit);
  }

  String _getHeightDisplay() {
    if (_selectedUnit == 'cm') {
      return '${_heightInCm.round()} cm';
    } else {
      final double totalInches = _heightInCm / 2.54;
      final int feet = (totalInches / 12).floor();
      final int inches = (totalInches % 12).round();
      return '$feet\'$inches"';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: creamBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header with icon and question
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.height,
                  color: primaryGreen,
                  size: isTablet ? 32 : 28,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  'How tall are you?',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.w600,
                    color: textDarkBrown,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Unit toggle - pill style
          DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildUnitToggle('Centimeters', 'cm', isTablet),
                _buildUnitToggle('Feet & Inches', 'ft', isTablet),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Selected height display - prominent
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Your Height',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: textLightBrown,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  _getHeightDisplay(),
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 36 : 32,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                if (_selectedUnit == 'cm') ...[
                  SizedBox(height: isTablet ? 4 : 2),
                  Text(
                    _getFeetInchesEquivalent(),
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 14 : 12,
                      color: textLightBrown,
                    ),
                  ),
                ] else ...[
                  SizedBox(height: isTablet ? 4 : 2),
                  Text(
                    _getCmEquivalent(),
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 14 : 12,
                      color: textLightBrown,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Inline scroll picker
          Container(
            height: isTablet ? 200 : 180,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
            ),
            child: _selectedUnit == 'cm'
                ? _buildCmPicker(isTablet)
                : _buildFeetInchesPicker(isTablet),
          ),

          SizedBox(height: isTablet ? 16 : 12),

          // Helper text with African touch
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_vertical,
                size: isTablet ? 18 : 16,
                color: textLightBrown,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                'Scroll to select your height',
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 14 : 12,
                  color: textLightBrown,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String label, String value, bool isTablet) {
    final isSelected = _selectedUnit == value;

    return GestureDetector(
      onTap: () => _onUnitChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textLightBrown,
          ),
        ),
      ),
    );
  }

  Widget _buildCmPicker(bool isTablet) => CupertinoPicker(
        scrollController: _cmController,
        itemExtent: isTablet ? 50 : 45,
        onSelectedItemChanged: _onCmChanged,
        selectionOverlay: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: primaryGreen.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
          ),
        ),
        children: List.generate(
          maxCm - minCm + 1,
          (index) {
            final int cm = minCm + index;
            final double totalInches = cm / 2.54;
            final int feet = (totalInches / 12).floor();
            final int inches = (totalInches % 12).round();

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$cm',
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: textDarkBrown,
                    ),
                  ),
                  Text(
                    'cm',
                    style: GoogleFonts.montserrat(
                      fontSize: isTablet ? 12 : 10,
                      color: textLightBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _buildFeetInchesPicker(bool isTablet) => Row(
        children: [
          // Feet picker
          Expanded(
            child: CupertinoPicker(
              scrollController: _feetController,
              itemExtent: isTablet ? 50 : 45,
              onSelectedItemChanged: (index) => _onFeetInchesChanged(),
              selectionOverlay: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: primaryGreen.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),
              children: List.generate(
                maxFeet - minFeet + 1,
                (index) {
                  final int feet = minFeet + index;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$feet',
                          style: GoogleFonts.montserrat(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: textDarkBrown,
                          ),
                        ),
                        Text(
                          'feet',
                          style: GoogleFonts.montserrat(
                            fontSize: isTablet ? 10 : 8,
                            color: textLightBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Separator with African pattern inspiration
          Container(
            width: 2,
            height: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryGreen.withValues(alpha: 0.1),
                  primaryGreen.withValues(alpha: 0.4),
                  primaryGreen.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          // Inches picker
          Expanded(
            child: CupertinoPicker(
              scrollController: _inchesController,
              itemExtent: isTablet ? 50 : 45,
              onSelectedItemChanged: (index) => _onFeetInchesChanged(),
              selectionOverlay: Container(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: primaryGreen.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
              ),
              children: List.generate(
                maxInches + 1,
                (index) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$index',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: textDarkBrown,
                        ),
                      ),
                      Text(
                        'inches',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 10 : 8,
                          color: textLightBrown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  String _getFeetInchesEquivalent() {
    final double totalInches = _heightInCm / 2.54;
    final int feet = (totalInches / 12).floor();
    final int inches = (totalInches % 12).round();
    return '$feet\'$inches"';
  }

  String _getCmEquivalent() => '${_heightInCm.round()} cm';
}
