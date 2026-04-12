import 'package:flutter/material.dart';

import 'settings_text_styles.dart';

/// Toggle row matching [SettingsRow] heights and typography.
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.isDestructive = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDestructive;

  static const double _hSingle = 54;
  static const double _hDouble = 76;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final danger = isDestructive && value;
    return SizedBox(
      height: hasSubtitle ? _hDouble : _hSingle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(
            title,
            style: SettingsTextStyles.rowTitle(
              context,
              color: danger ? Colors.red.shade700 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: hasSubtitle
              ? Text(
                  subtitle!,
                  style: SettingsTextStyles.rowSubtitle(context).copyWith(
                    color: danger ? Colors.red.shade400 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
