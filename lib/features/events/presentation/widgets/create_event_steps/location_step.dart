import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({
    required this.eventData,
    this.onLocationChanged,
    super.key,
  });
  final EventCreationData eventData;
  final VoidCallback? onLocationChanged;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  late TextEditingController _venueNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _venueNameController = TextEditingController(
      text: widget.eventData.location?.name ?? '',
    );
    _addressController = TextEditingController(
      text: widget.eventData.location?.address ?? '',
    );
    _cityController = TextEditingController(
      text: widget.eventData.location?.city ?? '',
    );
    _stateController = TextEditingController(
      text: widget.eventData.location?.state ?? '',
    );
    _countryController = TextEditingController(
      text: widget.eventData.location?.country ?? 'United States',
    );

    _venueNameController.addListener(_updateLocation);
    _addressController.addListener(_updateLocation);
    _cityController.addListener(_updateLocation);
    _stateController.addListener(_updateLocation);
    _countryController.addListener(_updateLocation);
  }

  void _updateLocation() {
    // Update location immediately to ensure validation has latest data
    widget.eventData.location = EventLocation(
      name: _venueNameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      country: _countryController.text.trim().isEmpty
          ? 'United States'
          : _countryController.text.trim(), // Default to US, allow user input
    );
    // Notify parent that location changed (triggers button state update)
    widget.onLocationChanged?.call();
  }

  @override
  void dispose() {
    _venueNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Where is your event?'),
            const SizedBox(height: 8),
            Text(
              'Help people find your event location',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            _buildVenueNameField(),
            const SizedBox(height: 20),
            _buildAddressField(),
            const SizedBox(height: 20),
            _buildCityField(),
            const SizedBox(height: 20),
            _buildStateSelector(),
            const SizedBox(height: 32),
            _buildLocationPreview(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      );

  Widget _buildVenueNameField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Venue Name *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _venueNameController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Lagos Continental Hotel',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF008037)
                    .withOpacity(0.7), // NaijaSingles green hint
              ),
              filled: true,
              fillColor:
                  AppColors.backgroundColor, // NaijaSingles cream background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.location_on,
                color: Color(0xFF008037),
              ),
            ),
          ),
        ],
      );

  Widget _buildAddressField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Street Address *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _addressController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'e.g., 52A Kofo Abayomi Street',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF008037)
                    .withOpacity(0.7), // NaijaSingles green hint
              ),
              filled: true,
              fillColor:
                  AppColors.backgroundColor, // NaijaSingles cream background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.home,
                color: Color(0xFF008037),
              ),
            ),
          ),
        ],
      );

  Widget _buildCityField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'City *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'e.g., Lagos',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF008037)
                    .withOpacity(0.7), // NaijaSingles green hint
              ),
              filled: true,
              fillColor:
                  AppColors.backgroundColor, // NaijaSingles cream background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.location_city,
                color: Color(0xFF008037),
              ),
            ),
          ),
        ],
      );

  Widget _buildStateSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _stateController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'Enter state (e.g., Lagos, Abuja, Kano)',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF008037)
                    .withOpacity(0.7), // NaijaSingles green hint
              ),
              filled: true,
              fillColor:
                  AppColors.backgroundColor, // NaijaSingles cream background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 20),

          // Country field
          Text(
            'Country *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _countryController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'Enter country (e.g., United States, Nigeria, Canada)',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF008037)
                    .withOpacity(0.7), // NaijaSingles green hint
              ),
              filled: true,
              fillColor:
                  AppColors.backgroundColor, // NaijaSingles cream background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      );

  Widget _buildLocationPreview() {
    if (widget.eventData.location == null ||
        widget.eventData.location!.name == null ||
        widget.eventData.location!.name!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF008037).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF008037).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF008037),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Location Preview',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF008037),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.eventData.location!.displayAddress,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037),
            ),
          ),
        ],
      ),
    );
  }
}
