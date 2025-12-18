import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Test helper class for common test utilities
class TestHelpers {
  /// Create a test MaterialApp wrapper
  static Widget createTestApp(Widget child) => MaterialApp(
      home: child,
    );

  /// Create a test MaterialApp with Provider wrapper
  static Widget createTestAppWithProvider<T extends ChangeNotifier>(
    T provider,
    Widget child,
  ) => MaterialApp(
      home: ChangeNotifierProvider<T>(
        create: (_) => provider,
        child: child,
      ),
    );

  /// Mock Firebase initialization for tests
  static void mockFirebaseForTests() {
    // This is a placeholder for Firebase mocking
    // In a real implementation, you would use firebase_core_mocks or similar
    TestWidgetsFlutterBinding.ensureInitialized();
  }
}
