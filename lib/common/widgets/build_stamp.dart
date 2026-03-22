import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../env.dart';

/// Internal build stamp for QA and TestFlight verification.
///
/// By default, hidden in production UI. Enable in release builds with:
/// --dart-define=SHOW_BUILD_STAMP=true
class BuildStamp extends StatelessWidget {
  const BuildStamp({super.key, this.compact = false});

  final bool compact;

  static const bool _showInRelease = bool.fromEnvironment('SHOW_BUILD_STAMP');

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode && !_showInRelease) {
      return const SizedBox.shrink();
    }

    final label = 'v${Environment.appVersion} • ${Environment.environment}';

    return IgnorePointer(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}
