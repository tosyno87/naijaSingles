import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/native_maps_config.dart';
import '../constants/app_colors.dart';

/// Defers constructing a [GoogleMap] until the native Maps SDK key is confirmed.
///
/// Use a [builder] (not a pre-built child) so `GoogleMap(...)` is not evaluated
/// when the key is missing — that path hard-crashes iOS TestFlight builds.
class NativeMapsGate extends StatefulWidget {
  const NativeMapsGate({
    required this.builder,
    this.fallback,
    this.loading,
    super.key,
  });

  /// Built only when [NativeMapsConfig.isApiKeyConfigured] is true.
  final WidgetBuilder builder;

  /// Shown when the native key is missing. Defaults to a short message.
  final WidgetBuilder? fallback;

  /// Shown while the platform channel is resolving.
  final Widget? loading;

  @override
  State<NativeMapsGate> createState() => _NativeMapsGateState();
}

class _NativeMapsGateState extends State<NativeMapsGate> {
  bool? _configured;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final bool ok = await NativeMapsConfig.ensureConfigured();
    if (!mounted) return;
    setState(() => _configured = ok);
  }

  @override
  Widget build(BuildContext context) {
    final bool? configured = _configured;
    if (configured == null) {
      return widget.loading ??
          const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }
    if (!configured) {
      if (widget.fallback != null) return widget.fallback!(context);
      return ColoredBox(
        color: const Color(0xFFE8E8E8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Map unavailable on this build.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
    return widget.builder(context);
  }
}
