import 'package:flutter/material.dart';

import 'settings_text_styles.dart';

/// Uppercase section label, 14 semibold muted, horizontal padding 16.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          label.toUpperCase(),
          style: SettingsTextStyles.sectionLabel(context),
        ),
      );
}
