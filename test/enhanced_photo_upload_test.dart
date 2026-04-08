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
    testWidgets('renders title, subtitle, and Add photos CTA',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add your photos'), findsOneWidget);
      expect(find.text('Add at least 3 to get started'), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('Photo grid is visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('bottom sheet shows Camera and Photo Library only',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const EnhancedPhotoUploadScreen()),
      );
      await tester.pumpAndSettle();

      // Tap the first grid cell to open the sheet
      final firstCell = find.byIcon(Icons.add).first;
      await tester.tap(firstCell);
      await tester.pumpAndSettle();

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photo Library'), findsOneWidget);

      // Removed options should not appear
      expect(find.text('Choose from Gallery'), findsNothing);
      expect(find.text('Choose multiple from gallery'), findsNothing);
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
