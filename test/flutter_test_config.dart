import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps every test file under `test/` to install a tolerant golden comparator.
/// CI (Linux) renders fonts and anti-aliasing slightly differently from macOS,
/// producing sub-pixel diffs (~0.3 %). A 0.5 % threshold absorbs these while
/// still catching real visual regressions.
Future<void> testExecutable(Future<void> Function() testMain) async {
  goldenFileComparator = _TolerantLocalFileComparator(
    Uri.parse('test'),
    tolerance: 0.005,
  );
  await testMain();
}

class _TolerantLocalFileComparator extends LocalFileComparator {
  _TolerantLocalFileComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= tolerance) {
      debugPrint(
        'Golden "$golden": ${result.diffPercent}% diff '
        '(within ${tolerance * 100}% tolerance)',
      );
      return true;
    }
    return result.passed;
  }
}
