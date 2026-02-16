import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../bloc/events_bloc.dart';
import '../../data/services/location_service.dart';

class AdvancedSearchDialog extends StatefulWidget {
  const AdvancedSearchDialog({
    required this.currentFilter,
    required this.onFilterApplied,
    super.key,
  });
  final EventFilter currentFilter;
  final Function(EventFilter) onFilterApplied;

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
  String? _eventType; // 'free', 'paid', or null (Any)

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
  static const double defaultRadiusKm = 25;

  // Conversion methods
  double _kmToMiles(double km) => km * 0.621371;
  double _milesToKm(double miles) => miles * 1.60934;

  List<double> get _radiusOptionsInCurrentUnit {
    if (_useMiles) {
      return radiusOptions.map(_kmToMiles).toList();
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
    _radiusKm = _filter.radiusKm ?? defaultRadiusKm; // Always have a default value
    
    // Initialize event type from filter
    if (_filter.freeOnly) {
      _eventType = 'free';
    } else if (_filter.paidOnly == true) {
      _eventType = 'paid';
    } else {
      _eventType = null; // Any
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationSection(),
                      _buildDivider(),
                      _buildDateRangeSection(),
                      _buildDivider(),
                      _buildCategorySection(),
                      _buildDivider(),
                      _buildEventTypeSection(),
                      const SizedBox(height: 8), // Bottom padding for scroll
                    ],
                  ),
                ),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
      );

  Widget _buildHeader() => Container(
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
                  color: const Color(0xFF333333),
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
                minWidth: 44,
                minHeight: 44,
              ),
            ),
          ],
        ),
      );

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE0E0E0),
        ),
      );

  Widget _buildLocationSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📍 Location',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          // City/address input
          TextFormField(
            controller: _locationController,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'City or address',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 15,
                color: const Color(0xFF999999),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF008037), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              fillColor: Colors.white,
              filled: true,
              prefixIcon: const Icon(
                Icons.location_on,
                size: 20,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Distance and location controls - visually grouped
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distance selector with explicit value display
                Row(
                  children: [
                    Text(
                      'Distance: ',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    DropdownButton<double>(
                      value: _radiusKm ?? defaultRadiusKm, // Always show a value
                      dropdownColor: Colors.white,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                      underline: Container(),
                      isExpanded: false,
                      items: _radiusOptionsInCurrentUnit
                          .map(
                            (radius) => DropdownMenuItem(
                              value: _useMiles
                                  ? _milesToKm(radius)
                                  : radius, // Store in km internally
                              child: Text(
                                '${radius.toStringAsFixed(radius.truncateToDouble() == radius ? 0 : 1)} ${_getRadiusUnit()}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _radiusKm = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Current location button - full width, no truncation
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      size: 16,
                      color: Color(0xFF008037),
                    ),
                    label: Text(
                      'Use current location',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF008037),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildDateRangeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Date',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start date',
                  date: _startDate,
                  onDateSelected: (date) {
                    setState(() {
                      _startDate = date;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: const Color(0xFF999999).withValues(alpha: 0.6),
                ),
              ),
              Expanded(
                child: _buildDateField(
                  label: 'End date',
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primaryGreen,
                    ),
                  ),
                  child: child!,
                ),
              );
              onDateSelected(selectedDate);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFF666666),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : 'Select date',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: date != null
                            ? const Color(0xFF333333)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildCategorySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏷 Category',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF008037), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              fillColor: Colors.white,
              filled: true,
            ),
            dropdownColor: Colors.white,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: const Color(0xFF333333),
            ),
            items: categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category == 'All' ? null : category,
                    child: Text(
                      category,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ],
      );

  Widget _buildEventTypeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎟 Event Type',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEventTypeChip(
                  label: 'Free',
                  value: 'free',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEventTypeChip(
                  label: 'Paid',
                  value: 'paid',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildEventTypeChip(
                  label: 'Any',
                  value: null,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildEventTypeChip({
    required String label,
    required String? value,
  }) {
    final isSelected = _eventType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _eventType = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF008037)
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF008037),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF008037)
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Secondary action: Clear All (text button)
              TextButton(
                onPressed: _clearFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF666666),
                  ),
                ),
              ),
              const Spacer(),
              // Primary action: Apply Filters (solid green)
              ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply filters',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  void _clearFilters() {
    setState(() {
      _filter = const EventFilter();
      _locationController.clear();
      _startDate = null;
      _endDate = null;
      _selectedCategory = null;
      _radiusKm = null;
      _useMiles = false;
      _eventType = null; // Any
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final location = await LocationService().getCurrentLocation();
      if (location != null) {
        setState(() {
          _locationController.text = 'Current Location';
          _radiusKm = _radiusKm ?? defaultRadiusKm;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location set to current position'),
              backgroundColor: Color(0xFF008037),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to get current location. Please check permissions.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _applyFilters() async {
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
            radiusKm = radiusKm ?? defaultRadiusKm;
          }
        } catch (e) {
          // If location access fails, show a message but continue with text-based filtering
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location access denied. Using text-based location filtering.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Text-based location search - no radius filtering
        radiusKm = null;
        userLatitude = null;
        userLongitude = null;
      }
    }

    // Apply event type filter
    final freeOnly = _eventType == 'free';
    final paidOnly = _eventType == 'paid';

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
      freeOnly: freeOnly,
      paidOnly: paidOnly ? true : null,
    );

    widget.onFilterApplied(newFilter);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

