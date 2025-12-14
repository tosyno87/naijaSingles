import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/events_bloc.dart';
import 'advanced_search_dialog.dart';

class EventFilterBar extends StatefulWidget {

  const EventFilterBar({
    required this.currentFilter, required this.onFilterChanged, super.key,
  });
  final EventFilter currentFilter;
  final Function(EventFilter) onFilterChanged;

  @override
  State<EventFilterBar> createState() => _EventFilterBarState();
}

class _EventFilterBarState extends State<EventFilterBar> {
  final ScrollController _scrollController = ScrollController();

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

  static const List<String> timeFilters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
    'Free Only',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildCategoryFilters(),
          const SizedBox(height: 12),
          _buildTimeFilters(),
          const SizedBox(height: 8),
          _buildAdvancedSearchButton(),
        ],
      ),
    );

  Widget _buildCategoryFilters() => SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == 'All'
              ? widget.currentFilter.category == null
              : widget.currentFilter.category?.toLowerCase() ==
                  category.toLowerCase();

          return Padding(
            padding:
                EdgeInsets.only(right: index == categories.length - 1 ? 0 : 12),
            child: _buildFilterChip(
              label: category,
              isSelected: isSelected,
              onTap: () => _onCategorySelected(category),
            ),
          );
        },
      ),
    );

  Widget _buildTimeFilters() => SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: timeFilters.length,
        itemBuilder: (context, index) {
          final timeFilter = timeFilters[index];
          final isSelected = _isTimeFilterSelected(timeFilter);

          return Padding(
            padding:
                EdgeInsets.only(right: index == timeFilters.length - 1 ? 0 : 8),
            child: _buildTimeFilterChip(
              label: timeFilter,
              isSelected: isSelected,
              onTap: () => _onTimeFilterSelected(timeFilter),
            ),
          );
        },
      ),
    );

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF008037) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF008037) : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF008037).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );

  Widget _buildTimeFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF008037).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF008037) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Free Only')
              Icon(
                Icons.money_off,
                size: 16,
                color: isSelected
                    ? const Color(0xFF008037)
                    : const Color(0xFF666666),
              ),
            if (label == 'Free Only') const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF008037)
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );

  void _onCategorySelected(String category) {
    final newFilter = widget.currentFilter.copyWith(
      category: category == 'All' ? null : category,
    );
    widget.onFilterChanged(newFilter);
  }

  void _onTimeFilterSelected(String timeFilter) {
    EventFilter newFilter;

    switch (timeFilter) {
      case 'All Time':
        newFilter = widget.currentFilter.copyWith(
          freeOnly: false,
        );
        break;
      case 'Today':
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay =
            DateTime(today.year, today.month, today.day, 23, 59, 59);
        newFilter = widget.currentFilter.copyWith(
          startDate: startOfDay,
          endDate: endOfDay,
          freeOnly: false,
        );
        break;
      case 'This Week':
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        newFilter = widget.currentFilter.copyWith(
          startDate:
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endDate: endOfWeek,
          freeOnly: false,
        );
        break;
      case 'This Month':
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        newFilter = widget.currentFilter.copyWith(
          startDate: startOfMonth,
          endDate: endOfMonth,
          freeOnly: false,
        );
        break;
      case 'Free Only':
        newFilter = widget.currentFilter.copyWith(
          freeOnly: !widget.currentFilter.freeOnly,
        );
        break;
      default:
        return;
    }

    widget.onFilterChanged(newFilter);
  }

  bool _isTimeFilterSelected(String timeFilter) {
    switch (timeFilter) {
      case 'All Time':
        return widget.currentFilter.startDate == null &&
            widget.currentFilter.endDate == null &&
            !widget.currentFilter.freeOnly;
      case 'Today':
        if (widget.currentFilter.startDate == null) return false;
        final today = DateTime.now();
        final filterDate = widget.currentFilter.startDate!;
        return filterDate.year == today.year &&
            filterDate.month == today.month &&
            filterDate.day == today.day;
      case 'This Week':
        if (widget.currentFilter.startDate == null) return false;
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final filterDate = widget.currentFilter.startDate!;
        return filterDate.year == startOfWeek.year &&
            filterDate.month == startOfWeek.month &&
            filterDate.day == startOfWeek.day;
      case 'This Month':
        if (widget.currentFilter.startDate == null) return false;
        final now = DateTime.now();
        final filterDate = widget.currentFilter.startDate!;
        return filterDate.year == now.year &&
            filterDate.month == now.month &&
            filterDate.day == 1;
      case 'Free Only':
        return widget.currentFilter.freeOnly;
      default:
        return false;
    }
  }

  Widget _buildAdvancedSearchButton() => Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.currentFilter.hasActiveFilters)
            GestureDetector(
              onTap: () {
                widget.onFilterChanged(const EventFilter());
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF008037).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF008037)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.clear,
                      size: 14,
                      color: Color(0xFF008037),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear Filters',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF008037),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox.shrink(),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AdvancedSearchDialog(
                  currentFilter: widget.currentFilter,
                  onFilterApplied: widget.onFilterChanged,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF008037),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Advanced',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
}

// Custom filter dialog for advanced filtering
class AdvancedFilterDialog extends StatefulWidget {

  const AdvancedFilterDialog({
    required this.currentFilter, required this.onApplyFilter, super.key,
  });
  final EventFilter currentFilter;
  final Function(EventFilter) onApplyFilter;

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  late EventFilter _tempFilter;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
    _locationController.text = widget.currentFilter.location ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            _buildLocationFilter(),
            const SizedBox(height: 20),
            _buildDateRangeFilter(),
            const SizedBox(height: 20),
            _buildFreeOnlyFilter(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );

  Widget _buildLocationFilter() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          style: GoogleFonts.montserrat(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter city or location',
            hintStyle: GoogleFonts.montserrat(color: const Color(0xFF999999)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF008037)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            _tempFilter = _tempFilter.copyWith(
              location: value.isEmpty ? null : value,
            );
          },
        ),
      ],
    );

  Widget _buildDateRangeFilter() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
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
              child: _buildDateButton(
                label: 'Start Date',
                date: _tempFilter.startDate,
                onTap: _selectStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                label: 'End Date',
                date: _tempFilter.endDate,
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
      ],
    );

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select date',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: date != null
                    ? const Color(0xFF333333)
                    : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildFreeOnlyFilter() => Row(
      children: [
        Checkbox(
          value: _tempFilter.freeOnly,
          onChanged: (value) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(freeOnly: value ?? false);
            });
          },
          activeColor: const Color(0xFF008037),
        ),
        Text(
          'Free events only',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF333333),
          ),
        ),
      ],
    );

  Widget _buildActionButtons() => Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              setState(() {
                _tempFilter = const EventFilter();
                _locationController.clear();
              });
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF666666),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onApplyFilter(_tempFilter);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008037),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply Filters',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _tempFilter.startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF008037),
            ),
          ),
          child: child!,
        ),
    );

    if (date != null) {
      setState(() {
        _tempFilter = _tempFilter.copyWith(startDate: date);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _tempFilter.endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _tempFilter.startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF008037),
            ),
          ),
          child: child!,
        ),
    );

    if (date != null) {
      setState(() {
        _tempFilter = _tempFilter.copyWith(endDate: date);
      });
    }
  }
}
