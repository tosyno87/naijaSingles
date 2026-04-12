import 'package:flutter/material.dart';

import 'settings_section_header.dart';
import 'settings_text_styles.dart';

/// Section with optional consequence copy (1–2 lines), then child rows.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    required this.title,
    required this.children,
    super.key,
    this.consequence,
  });

  final String title;
  final String? consequence;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSectionHeader(title),
          if (consequence != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                consequence!,
                style: SettingsTextStyles.consequence(context),
              ),
            ),
          ],
          ...children,
        ],
      );
}
