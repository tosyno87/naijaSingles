import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/events_bloc.dart';
import '../../data/services/location_service.dart';

class AdvancedSearchDialog extends StatefulWidget {
  final EventFilter currentFilter;
  final Function(EventFilter) onFilterApplied;

  const AdvancedSearchDialog({
    Key? key,
    required this.currentFilter,
    required this.onFilterApplied,
  }) : super(key: key);

  @override
  State<AdvancedSearchDialog> createState() => _AdvancedSearchDialogState();
}

class _AdvancedSearchDialogState extends State<AdvancedSearchDialog> {
  late EventFilter _filter;
  final TextEditingController _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  double? _radiusKm;
  bool _useMiles = false; // Default to km, but can switch to miles

  static const List<String> categories = [
    'All',
    'Music',
    'Business',
    'Community',
    'Food & Drink',
    'Arts',
    'Fashion',
    'Sports',
    'Technology',
  ];

  static const List<double> radiusOptions = [5, 10, 25, 50, 100];
  static const double defaultRadiusKm = 25.0;

  // Conversion methods
  double _kmToMiles(double km) => km * 0.621371;
  double _milesToKm(double miles) => miles * 1.60934;

  List<double> get _radiusOptionsInCurrentUnit {
    if (_useMiles) {
      return radiusOptions.map((km) => _kmToMiles(km)).toList();
    }
    return radiusOptions;
  }

  String _getRadiusUnit() => _useMiles ? 'miles' : 'km';

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
    _initializeFields();
  }

  void _initializeFields() {
    _locationController.text = _filter.location ?? '';
    _startDate = _filter.startDate;
    _endDate = _filter.endDate;
    _selectedCategory = _filter.category;
    _radiusKm = _filter.radiusKm;
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8), // NaijaSingles cream background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildDateRangeSection(),
                    const SizedBox(height: 24),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildPriceSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Advanced Search',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF008037),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Color(0xFF666666),
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          dropdownColor: const Color(0xFFE8F5E8),
          style: GoogleFonts.montserrat(color: const Color(0xFF333333)),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: const Color(0xFFE8F5E8), // NaijaSingles cream background
            filled: true,
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category == 'All' ? null : category,
              child: Text(category,
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFF333333))),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onDateSelected: (date) {
                  setState(() {
                    _startDate = date;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _endDate,
                onDateSelected: (date) {
                  setState(() {
                    _endDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF008037), // NaijaSingles green
                  onPrimary: Colors.white,
                  surface: Color(0xFFE8F5E8), // NaijaSingles cream background
                  onSurface: Color(0xFF333333), // Dark text
                  secondary: Color(0xFF008037),
                  onSecondary: Colors.white,
                ),
                dialogBackgroundColor:
                    const Color(0xFFE8F5E8), // Cream background
                textTheme: Theme.of(context).textTheme.copyWith(
                      bodyLarge: GoogleFonts.montserrat(
                        color: const Color(0xFF333333),
                      ),
                      bodyMedium: GoogleFonts.montserrat(
                        color: const Color(0xFF333333),
                      ),
                    ),
              ),
              child: child!,
            );
          },
        );
        onDateSelected(selectedDate);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE8F5E8), // NaijaSingles cream background
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 20,
              color: const Color(0xFF333333),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: date != null
                      ? const Color(0xFF333333)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          style: GoogleFonts.montserrat(color: const Color(0xFF333333)),
          decoration: InputDecoration(
            hintText: 'Enter city or address',
            hintStyle: GoogleFonts.montserrat(color: const Color(0xFF666666)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: const Color(0xFFE8F5E8), // NaijaSingles cream background
            filled: true,
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF333333)),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Within ',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF333333)),
                ),
                DropdownButton<double>(
                  value: _radiusKm,
                  dropdownColor: const Color(0xFFE8F5E8),
                  style: GoogleFonts.montserrat(color: const Color(0xFF333333)),
                  items: _radiusOptionsInCurrentUnit.map((radius) {
                    return DropdownMenuItem(
                      value: _useMiles
                          ? _milesToKm(radius)
                          : radius, // Store in km internally
                      child: Text(
                          '${radius.toStringAsFixed(1)} ${_getRadiusUnit()}',
                          style: GoogleFonts.montserrat(
                              color: const Color(0xFF333333))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                ),
                Text(
                  ' of location',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: const Color(0xFF333333)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Distance unit: ',
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: const Color(0xFF666666)),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _useMiles = !_useMiles;
                      // Convert current radius to new unit
                      if (_radiusKm != null) {
                        if (_useMiles) {
                          _radiusKm = _kmToMiles(_radiusKm!);
                        } else {
                          _radiusKm = _milesToKm(_radiusKm!);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _useMiles
                          ? const Color(0xFF008037)
                          : Colors.transparent,
                      border: Border.all(color: const Color(0xFF008037)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _useMiles ? 'Miles' : 'Kilometers',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color:
                            _useMiles ? Colors.white : const Color(0xFF008037),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('Use Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Type',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        _buildModernFilterChip(
          label: 'Free Events Only',
          isSelected: _filter.freeOnly,
          onTap: () {
            setState(() {
              _filter = _filter.copyWith(freeOnly: !_filter.freeOnly);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildModernFilterChip(
          label: 'Paid Events Only',
          isSelected: _filter.paidOnly ?? false,
          onTap: () {
            setState(() {
              _filter =
                  _filter.copyWith(paidOnly: !(_filter.paidOnly ?? false));
            });
          },
        ),
      ],
    );
  }

  Widget _buildModernFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF008037) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF008037)
                      : const Color(0xFFCCCCCC),
                  width: 2,
                ),
                color:
                    isSelected ? const Color(0xFF008037) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF008037)
                      : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF008037), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                'Clear All',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008037),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008037),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filter = const EventFilter();
      _locationController.clear();
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _radiusKm = null;
      _useMiles = false; // Reset to default km
    });
  }

  void _useCurrentLocation() async {
    try {
      final location = await LocationService().getCurrentLocation();
      if (location != null) {
        setState(() {
          _locationController.text = 'Current Location';
          _radiusKm =
              _radiusKm ?? defaultRadiusKm; // Default to 25km if not set
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location set to current position'),
            backgroundColor: const Color(0xFF008037),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unable to get current location. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilters() async {
    // Get user's current location if location filter is being used
    double? userLatitude;
    double? userLongitude;
    double? radiusKm = _radiusKm;

    if (_locationController.text.trim().isNotEmpty) {
      if (_locationController.text.trim() == 'Current Location') {
        // Use current location with radius
        try {
          final location = await LocationService().getCurrentLocation();
          if (location != null) {
            userLatitude = location.latitude;
            userLongitude = location.longitude;
            radiusKm = radiusKm ?? defaultRadiusKm; // Ensure we have a radius
          }
        } catch (e) {
          // If location access fails, show a message but continue with text-based filtering
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Location access denied. Using text-based location filtering.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Text-based location search - no radius filtering
        radiusKm = null;
        userLatitude = null;
        userLongitude = null;
      }
    }

    final newFilter = _filter.copyWith(
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      radiusKm: radiusKm,
      latitude: userLatitude,
      longitude: userLongitude,
    );

    widget.onFilterApplied(newFilter);
    Navigator.of(context).pop();
  }
}
