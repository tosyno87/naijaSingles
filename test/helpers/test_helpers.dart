import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Test helper class for common test utilities
class TestHelpers {
  /// Create a test MaterialApp wrapper
  static Widget createTestApp(Widget child) => MaterialApp(
        home: child,
      );

  /// Create a test MaterialApp with BlocProvider wrapper
  static Widget createTestAppWithBloc<B extends BlocBase<Object>>(
    B bloc,
    Widget child,
  ) =>
      MaterialApp(
        home: BlocProvider<B>.value(
          value: bloc,
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
