import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IOSHeightPicker extends StatefulWidget {

  const IOSHeightPicker({
    required this.initialHeight, required this.initialUnit, required this.onChanged, super.key,
  });
  final double initialHeight; // Height in cm
  final String initialUnit; // 'cm' or 'ft'
  final Function(double height, String unit) onChanged;

  @override
  State<IOSHeightPicker> createState() => _IOSHeightPickerState();
}

class _IOSHeightPickerState extends State<IOSHeightPicker> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unit toggle
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onUnitChanged('cm'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedUnit == 'cm'
                          ? const Color(0xFF008037)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Centimeters',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedUnit == 'cm'
                            ? Colors.white
                            : Colors.black54,
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
                      vertical: isTablet ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedUnit == 'ft'
                          ? const Color(0xFF008037)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Feet & Inches',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedUnit == 'ft'
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isTablet ? 24 : 20),

        // Height display
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 20,
              vertical: isTablet ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF008037).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF008037).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _getHeightDisplay(),
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF008037),
              ),
            ),
          ),
        ),

        SizedBox(height: isTablet ? 24 : 20),

        // iOS-style picker
        Container(
          height: isTablet ? 200 : 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _selectedUnit == 'cm'
              ? _buildCmPicker()
              : _buildFeetInchesPicker(),
        ),

        SizedBox(height: isTablet ? 16 : 12),

        // Helper text
        Center(
          child: Text(
            _selectedUnit == 'cm'
                ? 'Scroll to select your height in centimeters'
                : 'Scroll to select your height in feet and inches',
            style: GoogleFonts.montserrat(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCmPicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return CupertinoPicker(
      scrollController: _cmController,
      itemExtent: isTablet ? 50 : 45,
      onSelectedItemChanged: _onCmChanged,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: const Color(0xFF008037).withValues(alpha: 0.3),
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
                  '$cm cm',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$feet\'$inches"',
                  style: GoogleFonts.montserrat(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeetInchesPicker() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Row(
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
                    color: const Color(0xFF008037).withValues(alpha: 0.3),
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
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'feet',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 12 : 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Separator
        Container(
          width: 1,
          height: double.infinity,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 20),
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
                    color: const Color(0xFF008037).withValues(alpha: 0.3),
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
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'inches',
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 12 : 10,
                          color: Colors.grey.shade600,
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
  }
}
