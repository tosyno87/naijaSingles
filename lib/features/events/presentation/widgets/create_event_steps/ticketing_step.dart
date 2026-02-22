import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class TicketingStep extends StatefulWidget {
  const TicketingStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<TicketingStep> createState() => _TicketingStepState();
}

class _TicketingStepState extends State<TicketingStep> {
  late TextEditingController _priceController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.eventData.ticketPrice?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.eventData.maxAttendees.toString(),
    );

    _priceController.addListener(() {
      final price = double.tryParse(_priceController.text);
      widget.eventData.ticketPrice = price;
    });

    _capacityController.addListener(() {
      final capacity = int.tryParse(_capacityController.text);
      if (capacity != null && capacity > 0) {
        widget.eventData.maxAttendees = capacity;
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Event Pricing & Capacity'),
            const SizedBox(height: 8),
            Text(
              'Set your event pricing and attendance limits',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            _buildPricingSection(),
            const SizedBox(height: 32),
            _buildCapacitySection(),
            const SizedBox(height: 32),
            _buildPricingSummary(),
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

  Widget _buildPricingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Pricing',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          // Free/Paid toggle
          Row(
            children: [
              Expanded(
                child: _buildPricingOption(
                  title: 'Free Event',
                  subtitle: 'No charge for attendees',
                  isSelected: widget.eventData.isFree,
                  onTap: () {
                    setState(() {
                      widget.eventData.isFree = true;
                      widget.eventData.ticketPrice = null;
                      _priceController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPricingOption(
                  title: 'Paid Event',
                  subtitle: 'Charge for tickets',
                  isSelected: !widget.eventData.isFree,
                  onTap: () {
                    setState(() {
                      widget.eventData.isFree = false;
                    });
                  },
                ),
              ),
            ],
          ),

          // Price input for paid events
          if (!widget.eventData.isFree) ...[
            const SizedBox(height: 20),

            // Currency selector
            Text(
              'Currency *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF008037).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.eventData.currency,
                  isExpanded: true,
                  dropdownColor: AppColors
                      .backgroundColor, // Afropeep cream background
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF666666),
                  ),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'USD',
                      child: Row(
                        children: [
                          Text(
                            r'$',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('US Dollar (USD)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'NGN',
                      child: Row(
                        children: [
                          Text(
                            '₦',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Nigerian Naira (NGN)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Row(
                        children: [
                          Text(
                            r'$',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('US Dollar (USD)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'GBP',
                      child: Row(
                        children: [
                          Text(
                            '£',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('British Pound (GBP)'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Row(
                        children: [
                          Text(
                            '€',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Euro (EUR)'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        widget.eventData.currency = newValue;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Ticket Price (${widget.eventData.currencySymbol}) *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: 'Enter ticket price',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF999999),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF008037), width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    r'$',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF008037),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platform fee: 10% + payment processing fees will be deducted',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ],
      );

  Widget _buildPricingOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF008037).withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF008037)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? const Color(0xFF008037)
                        : const Color(0xFF999999),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF008037)
                            : const Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCapacitySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Capacity',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the maximum number of attendees for your event',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF333333),
            ),
            decoration: InputDecoration(
              hintText: 'Maximum attendees',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF999999),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF008037), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.people,
                color: Color(0xFF008037),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recommended: Start with a smaller capacity for your first event',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      );

  Widget _buildPricingSummary() {
    if (widget.eventData.isFree) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF008037).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF008037).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Color(0xFF008037),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Free Event Summary',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Ticket Price', 'Free'),
            _buildSummaryRow(
              'Max Attendees',
              '${widget.eventData.maxAttendees}',
            ),
            _buildSummaryRow('Platform Fee', 'None'),
          ],
        ),
      );
    } else {
      final ticketPrice = widget.eventData.ticketPrice ?? 0;
      final platformFee = ticketPrice * 0.10; // 10% platform fee
      final processingFee = (ticketPrice * 0.029) + 0.30; // 2.9% + $0.30
      final creatorEarnings = ticketPrice - platformFee - processingFee;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF008037).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF008037).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF008037),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Paid Event Summary',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Ticket Price',
              '${widget.eventData.currencySymbol}${ticketPrice.toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'Max Attendees',
              '${widget.eventData.maxAttendees}',
            ),
            _buildSummaryRow(
              'Platform Fee (10%)',
              '${widget.eventData.currencySymbol}${platformFee.toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'Processing Fee',
              '${widget.eventData.currencySymbol}${processingFee.toStringAsFixed(2)}',
            ),
            const Divider(color: Color(0xFF008037)),
            _buildSummaryRow(
              'Your Earnings per Ticket',
              '${widget.eventData.currencySymbol}${creatorEarnings.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF008037),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                color: const Color(0xFF008037),
              ),
            ),
          ],
        ),
      );
}
