import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

class EventDescriptionSection extends StatefulWidget {
  const EventDescriptionSection({
    required this.description,
    super.key,
  });

  final String description;

  @override
  State<EventDescriptionSection> createState() =>
      _EventDescriptionSectionState();
}

class _EventDescriptionSectionState extends State<EventDescriptionSection> {
  bool _showFull = false;

  @override
  Widget build(BuildContext context) {
    if (widget.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'About This Event'.tr(),
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3E1F0D),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                  maxLines: _showFull ? null : 3,
                  overflow: _showFull ? null : TextOverflow.ellipsis,
                ),
                if (widget.description.length > 150) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    button: true,
                    label: _showFull ? 'Show Less'.tr() : 'Read More'.tr(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _showFull = !_showFull),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            _showFull ? 'Show Less'.tr() : 'Read More'.tr(),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
