import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AfropeepHeightDropdown extends StatefulWidget {
  final String? initialHeightFtIn;
  final int? initialHeightCm;
  final Function(String heightFtIn, int heightCm) onChanged;

  const AfropeepHeightDropdown({
    Key? key,
    this.initialHeightFtIn,
    this.initialHeightCm,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<AfropeepHeightDropdown> createState() => _AfropeepHeightDropdownState();
}

class _AfropeepHeightDropdownState extends State<AfropeepHeightDropdown> {
  String? _selectedHeightFtIn;
  int? _selectedHeightCm;

  // Pre-computed height pairs from 4'10" to 6'6"
  static const List<Map<String, dynamic>> _heightOptions = [
    {'ft_in': '4\'10"', 'cm': 147, 'display': '4\'10" (147 cm)'},
    {'ft_in': '4\'11"', 'cm': 150, 'display': '4\'11" (150 cm)'},
    {'ft_in': '5\'0"', 'cm': 152, 'display': '5\'0" (152 cm)'},
    {'ft_in': '5\'1"', 'cm': 155, 'display': '5\'1" (155 cm)'},
    {'ft_in': '5\'2"', 'cm': 157, 'display': '5\'2" (157 cm)'},
    {'ft_in': '5\'3"', 'cm': 160, 'display': '5\'3" (160 cm)'},
    {'ft_in': '5\'4"', 'cm': 163, 'display': '5\'4" (163 cm)'},
    {'ft_in': '5\'5"', 'cm': 165, 'display': '5\'5" (165 cm)'},
    {'ft_in': '5\'6"', 'cm': 168, 'display': '5\'6" (168 cm)'},
    {'ft_in': '5\'7"', 'cm': 170, 'display': '5\'7" (170 cm)'}, // Default
    {'ft_in': '5\'8"', 'cm': 173, 'display': '5\'8" (173 cm)'},
    {'ft_in': '5\'9"', 'cm': 175, 'display': '5\'9" (175 cm)'},
    {'ft_in': '5\'10"', 'cm': 178, 'display': '5\'10" (178 cm)'},
    {'ft_in': '5\'11"', 'cm': 180, 'display': '5\'11" (180 cm)'},
    {'ft_in': '6\'0"', 'cm': 183, 'display': '6\'0" (183 cm)'},
    {'ft_in': '6\'1"', 'cm': 185, 'display': '6\'1" (185 cm)'},
    {'ft_in': '6\'2"', 'cm': 188, 'display': '6\'2" (188 cm)'},
    {'ft_in': '6\'3"', 'cm': 191, 'display': '6\'3" (191 cm)'},
    {'ft_in': '6\'4"', 'cm': 193, 'display': '6\'4" (193 cm)'},
    {'ft_in': '6\'5"', 'cm': 196, 'display': '6\'5" (196 cm)'},
    {'ft_in': '6\'6"', 'cm': 198, 'display': '6\'6" (198 cm)'},
  ];

  // Afropeep colors
  static const Color backgroundColor = Color(0xFFFFF6E5);
  static const Color primaryGreen = Color(0xFF008037);
  static const Color textGray = Color(0xFF666666);
  static const Color textDark = Color(0xFF333333);

  @override
  void initState() {
    super.initState();

    // Set initial values or default to 5'7" (170 cm)
    if (widget.initialHeightFtIn != null && widget.initialHeightCm != null) {
      _selectedHeightFtIn = widget.initialHeightFtIn;
      _selectedHeightCm = widget.initialHeightCm;
    } else {
      // Default to 5'7" (170 cm)
      final defaultHeight = _heightOptions.firstWhere(
        (option) => option['ft_in'] == '5\'7"',
      );
      _selectedHeightFtIn = defaultHeight['ft_in'];
      _selectedHeightCm = defaultHeight['cm'];

      // Notify parent of default selection
      widget.onChanged(_selectedHeightFtIn!, _selectedHeightCm!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: EdgeInsets.only(
              left: isTablet ? 4 : 2,
              bottom: isTablet ? 8 : 6,
            ),
            child: Text(
              'Select your height',
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),

          // Dropdown
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 4 : 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: primaryGreen,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedHeightFtIn,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: primaryGreen,
                  size: isTablet ? 24 : 20,
                ),
                style: GoogleFonts.montserrat(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                menuMaxHeight: MediaQuery.of(context).size.height * 0.4,
                items: _heightOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option['ft_in'],
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isTablet ? 12 : 8,
                        horizontal: isTablet ? 8 : 4,
                      ),
                      child: Text(
                        option['display'],
                        style: GoogleFonts.montserrat(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: textDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final selectedOption = _heightOptions.firstWhere(
                      (option) => option['ft_in'] == newValue,
                    );

                    setState(() {
                      _selectedHeightFtIn = selectedOption['ft_in'];
                      _selectedHeightCm = selectedOption['cm'];
                    });

                    widget.onChanged(_selectedHeightFtIn!, _selectedHeightCm!);
                  }
                },
              ),
            ),
          ),

          // Caption
          Padding(
            padding: EdgeInsets.only(
              left: isTablet ? 4 : 2,
              top: isTablet ? 8 : 6,
            ),
            child: Text(
              'Height helps with better matching',
              style: GoogleFonts.montserrat(
                fontSize: isTablet ? 12 : 11,
                fontWeight: FontWeight.w400,
                color: textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class to get height data
class HeightData {
  static const String defaultHeightFtIn = '5\'7"';
  static const int defaultHeightCm = 170;

  // Get cm value from ft/in string
  static int? getCmFromFtIn(String ftIn) {
    try {
      final option = _AfropeepHeightDropdownState._heightOptions.firstWhere(
        (option) => option['ft_in'] == ftIn,
      );
      return option['cm'];
    } catch (e) {
      return null;
    }
  }

  // Get ft/in string from cm value
  static String? getFtInFromCm(int cm) {
    try {
      final option = _AfropeepHeightDropdownState._heightOptions.firstWhere(
        (option) => option['cm'] == cm,
      );
      return option['ft_in'];
    } catch (e) {
      return null;
    }
  }

  // Get display string from ft/in
  static String? getDisplayFromFtIn(String ftIn) {
    try {
      final option = _AfropeepHeightDropdownState._heightOptions.firstWhere(
        (option) => option['ft_in'] == ftIn,
      );
      return option['display'];
    } catch (e) {
      return null;
    }
  }

  // Get all height options
  static List<Map<String, dynamic>> get allHeightOptions =>
      _AfropeepHeightDropdownState._heightOptions;
}
