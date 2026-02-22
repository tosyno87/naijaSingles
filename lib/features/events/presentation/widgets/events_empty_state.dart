import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.onCreateEvent,
    super.key,
  });

  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_available,
                    size: 50,
                    color: Color(0xFF999999),
                    semanticLabel: 'No events icon',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Events Found'.tr(),
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3E1F0D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  hasActiveFilters
                      ? 'Try adjusting your search or filters to find more events'
                          .tr()
                      : 'Be the first to create an event and start bringing people together!'
                          .tr(),
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (hasActiveFilters)
                  _buildActionButton(
                    label: 'Clear Filters'.tr(),
                    onTap: onClearFilters,
                  )
                else
                  _buildActionButton(
                    label: 'Create Event'.tr(),
                    onTap: onCreateEvent,
                    icon: Icons.add,
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) =>
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
