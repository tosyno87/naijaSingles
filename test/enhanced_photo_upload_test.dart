import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/bloc/user/user_bloc.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';
import 'package:naijasingles/features/onboarding/screens/enhanced_photo_upload_screen.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class MockUserBloc extends Mock implements UserBloc {}

void main() {
  late MockOnboardingRepository mockRepository;
  late MockUserBloc mockUserBloc;

  setUp(() {
    mockRepository = MockOnboardingRepository();
    mockUserBloc = MockUserBloc();
  });

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<OnboardingBloc>(
        create: (_) => OnboardingBloc(
          repository: mockRepository,
          userBloc: mockUserBloc,
        ),
        child: Scaffold(body: child),
      ),
    );
  }

  group('Enhanced Photo Upload Screen Tests', () {
    testWidgets('Enhanced photo upload screen renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add your best photos'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Photo grid is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      // Verify scrollable photo grid is present
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Screen has app bar and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add your best photos'), findsOneWidget);
    });
  });

  group('Photo Type Guidance Tests', () {
    test('Photo type guidance provides correct information', () {
      const guidance = PhotoTypeGuidance(
        type: PhotoType.closeUp,
        title: 'Main Photo',
        description: 'A clear, smiling face shot with good lighting',
        isPrimary: true,
      );

      expect(guidance.type, PhotoType.closeUp);
      expect(guidance.title, 'Main Photo');
      expect(guidance.isPrimary, true);
    });

    test('All photo types are defined', () {
      expect(PhotoType.values.length, 5);
      expect(PhotoType.values, contains(PhotoType.closeUp));
      expect(PhotoType.values, contains(PhotoType.fullBody));
      expect(PhotoType.values, contains(PhotoType.activity));
      expect(PhotoType.values, contains(PhotoType.social));
      expect(PhotoType.values, contains(PhotoType.lifestyle));
    });
  });
}
