import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class DateTimeStep extends StatefulWidget {
  const DateTimeStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends State<DateTimeStep> {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('When is your event?'),
            const SizedBox(height: 8),
            Text(
              'Set the date and time for your event',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 32),
            _buildStartDateTimeSection(),
            const SizedBox(height: 32),
            _buildEndDateTimeSection(),
            const SizedBox(height: 32),
            _buildDurationInfo(),
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

  Widget _buildStartDateTimeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Date & Time *',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDateSelector(
                  label: 'Date',
                  selectedDate: widget.eventData.startDate,
                  onDateSelected: (date) {
                    setState(() {
                      if (widget.eventData.startDate != null) {
                        // Preserve the time when changing date
                        final time =
                            TimeOfDay.fromDateTime(widget.eventData.startDate!);
                        widget.eventData.startDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      } else {
                        widget.eventData.startDate = date;
                      }

                      // Adjust end date if it's before start date
                      if (widget.eventData.endDate != null &&
                          widget.eventData.endDate!
                              .isBefore(widget.eventData.startDate!)) {
                        widget.eventData.endDate =
                            widget.eventData.startDate!.add(
                          const Duration(hours: 2),
                        );
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeSelector(
                  label: 'Time',
                  selectedTime: widget.eventData.startDate != null
                      ? TimeOfDay.fromDateTime(widget.eventData.startDate!)
                      : null,
                  onTimeSelected: (time) {
                    setState(() {
                      final now = DateTime.now();
                      final selectedDate = widget.eventData.startDate ?? now;
                      widget.eventData.startDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );

                      // Adjust end date if it's before start date
                      if (widget.eventData.endDate != null &&
                          widget.eventData.endDate!
                              .isBefore(widget.eventData.startDate!)) {
                        widget.eventData.endDate =
                            widget.eventData.startDate!.add(
                          const Duration(hours: 2),
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildEndDateTimeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'End Date & Time *',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDateSelector(
                  label: 'Date',
                  selectedDate: widget.eventData.endDate,
                  onDateSelected: (date) {
                    setState(() {
                      if (widget.eventData.endDate != null) {
                        // Preserve the time when changing date
                        final time =
                            TimeOfDay.fromDateTime(widget.eventData.endDate!);
                        widget.eventData.endDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      } else {
                        widget.eventData.endDate = date;
                      }
                    });
                  },
                  minDate: widget.eventData.startDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeSelector(
                  label: 'Time',
                  selectedTime: widget.eventData.endDate != null
                      ? TimeOfDay.fromDateTime(widget.eventData.endDate!)
                      : null,
                  onTimeSelected: (time) {
                    setState(() {
                      final selectedDate = widget.eventData.endDate ??
                          widget.eventData.startDate ??
                          DateTime.now();
                      widget.eventData.endDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildDateSelector({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    DateTime? minDate,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                _selectDate(context, selectedDate, onDateSelected, minDate),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    AppColors.backgroundColor, // NaijaSingles cream background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF008037),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? _dateFormat.format(selectedDate)
                          : 'Select date',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: selectedDate != null
                            ? const Color(0xFF333333)
                            : const Color(0xFF008037)
                                .withOpacity(0.7), // NaijaSingles green hint
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onTimeSelected,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectTime(context, selectedTime, onTimeSelected),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    AppColors.backgroundColor, // NaijaSingles cream background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF008037)
                      .withOpacity(0.3), // NaijaSingles green border
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF008037),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime != null
                          ? selectedTime.format(context)
                          : 'Select time',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: selectedTime != null
                            ? const Color(0xFF333333)
                            : const Color(0xFF008037)
                                .withOpacity(0.7), // NaijaSingles green hint
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildDurationInfo() {
    if (widget.eventData.startDate == null ||
        widget.eventData.endDate == null) {
      return const SizedBox.shrink();
    }

    final duration =
        widget.eventData.endDate!.difference(widget.eventData.startDate!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    String durationText;
    if (hours > 0 && minutes > 0) {
      durationText = '${hours}h ${minutes}m';
    } else if (hours > 0) {
      durationText = '${hours}h';
    } else {
      durationText = '${minutes}m';
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
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            color: Color(0xFF008037),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event Duration',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
                Text(
                  durationText,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF008037),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
    DateTime? minDate,
  ) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? now.add(const Duration(days: 1));
    final firstDate = minDate ?? now;
    final lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF008037),
            onSurface: Color(0xFF333333),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      onDateSelected(pickedDate);
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay? selectedTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final initialTime = selectedTime ?? TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF008037),
            onSurface: Color(0xFF333333),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedTime != null) {
      onTimeSelected(pickedTime);
    }
  }
}
