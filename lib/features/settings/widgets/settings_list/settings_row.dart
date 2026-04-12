import 'package:flutter/material.dart';

import 'settings_text_styles.dart';

/// Navigation row: title 17 semibold, optional subtitle 15 muted, chevron.
/// Heights: 54 single-line, 76 with subtitle.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    super.key,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;
  final Widget? trailing;

  static const double _hSingle = 54;
  static const double _hDouble = 76;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final titleStyle = SettingsTextStyles.rowTitle(
      context,
      color: destructive ? Colors.red.shade700 : null,
      fontWeight: FontWeight.w600,
    );

    final row = SizedBox(
      height: hasSubtitle ? _hDouble : _hSingle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: SettingsTextStyles.rowSubtitle(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron && trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade500
                    : Colors.grey.shade600,
                size: 22,
              ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return row;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}
