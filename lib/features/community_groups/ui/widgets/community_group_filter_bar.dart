import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommunityGroupFilterBar extends StatelessWidget {
  const CommunityGroupFilterBar({
    required this.selectedCategory,
    required this.selectedCountry,
    required this.onCategoryChanged,
    required this.onCountryChanged,
    super.key,
  });
  final String selectedCategory;
  final String selectedCountry;
  final Function(String) onCategoryChanged;
  final Function(String) onCountryChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories
            Text(
              'Categories',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', selectedCategory, onCategoryChanged),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Cultural',
                    selectedCategory,
                    onCategoryChanged,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Professional',
                    selectedCategory,
                    onCategoryChanged,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Interest',
                    selectedCategory,
                    onCategoryChanged,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Location',
                    selectedCategory,
                    onCategoryChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Countries
            Text(
              'Countries',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', selectedCountry, onCountryChanged),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Nigeria', selectedCountry, onCountryChanged),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ghana', selectedCountry, onCountryChanged),
                  const SizedBox(width: 8),
                  _buildFilterChip('Kenya', selectedCountry, onCountryChanged),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'South Africa',
                    selectedCountry,
                    onCountryChanged,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      'Ethiopia', selectedCountry, onCountryChanged),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilterChip(
    String label,
    String selected,
    Function(String) onChanged,
  ) {
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF008037) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF008037) : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF008037).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}
