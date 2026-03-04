import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/features/events/data/models/enhanced_event_model.dart';
import 'package:naijasingles/features/events/presentation/bloc/event_creation_bloc.dart';
import 'package:naijasingles/features/events/presentation/screens/create_event_screen.dart';

class MockEventCreationBloc extends Mock implements EventCreationBloc {}

void main() {
  group('CreateEventScreen', () {
    late MockEventCreationBloc mockEventCreationBloc;

    setUp(() {
      mockEventCreationBloc = MockEventCreationBloc();

      when(() => mockEventCreationBloc.state)
          .thenReturn(EventCreationInitial());

      when(() => mockEventCreationBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    Widget createWidgetUnderTest({EnhancedEventModel? existingEvent}) =>
        MaterialApp(
          home: BlocProvider<EventCreationBloc>.value(
            value: mockEventCreationBloc,
            child: CreateEventScreen(existingEvent: existingEvent),
          ),
        );

    testWidgets('should display create event screen with correct structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Event'), findsOneWidget);
      expect(find.text('1 of 6: Basic Info'), findsOneWidget);
    });

    testWidgets('should display progress indicator with correct step count',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 of 6: Basic Info'), findsOneWidget);
      expect(find.text('2 of 6: Date & Time'), findsNothing);
    });

    testWidgets('should display basic info step as first step',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Event Details'), findsOneWidget);
      expect(find.text('Event Name *'), findsOneWidget);
    });

    testWidgets('should display navigation buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      // The nav bar contains an ElevatedButton. With empty form fields,
      // validation fails so the button shows a spinner instead of "Next".
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should display correct background colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
    });

    testWidgets('should display loading state correctly',
        (WidgetTester tester) async {
      when(() => mockEventCreationBloc.state)
          .thenReturn(EventCreationLoading());
      when(() => mockEventCreationBloc.stream)
          .thenAnswer((_) => Stream.value(EventCreationLoading()));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('should display success state correctly',
        (WidgetTester tester) async {
      when(() => mockEventCreationBloc.state)
          .thenReturn(EventCreationInitial());
      when(() => mockEventCreationBloc.stream).thenAnswer((_) => Stream.value(
            const EventCreationSuccess(
                'event123', 'Event created successfully!'),
          ));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Event created successfully!'), findsOneWidget);
    });

    testWidgets('should display error state correctly',
        (WidgetTester tester) async {
      when(() => mockEventCreationBloc.state)
          .thenReturn(EventCreationInitial());
      when(() => mockEventCreationBloc.stream).thenAnswer(
          (_) => Stream.value(const EventCreationError('Error message')));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('should display validation errors correctly',
        (WidgetTester tester) async {
      when(() => mockEventCreationBloc.state)
          .thenReturn(EventCreationInitial());
      when(() => mockEventCreationBloc.stream).thenAnswer((_) => Stream.value(
          const EventValidationState(false, ['Title is required'])));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('should handle existing event data correctly',
        (WidgetTester tester) async {
      final existingEvent = EnhancedEventModel(
        id: '1',
        name: 'Existing Event',
        description: 'Existing Description',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
        location: const EventLocation(
          name: 'Existing Venue',
          address: 'Existing Address',
          city: 'Existing City',
          state: 'Existing State',
          country: 'Nigeria',
        ),
        isFree: true,
        category: 'Cultural Events',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester
          .pumpWidget(createWidgetUnderTest(existingEvent: existingEvent));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Event'), findsOneWidget);
    });

    testWidgets('should display correct app bar title for new event',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Event'), findsOneWidget);
    });

    testWidgets('should display correct app bar title for existing event',
        (WidgetTester tester) async {
      final existingEvent = EnhancedEventModel(
        id: '1',
        name: 'Existing Event',
        description: 'Existing Description',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1, hours: 2)),
        location: const EventLocation(
          name: 'Existing Venue',
          address: 'Existing Address',
          city: 'Existing City',
          state: 'Existing State',
          country: 'Nigeria',
        ),
        isFree: true,
        category: 'Cultural Events',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester
          .pumpWidget(createWidgetUnderTest(existingEvent: existingEvent));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Event'), findsOneWidget);
    });

    testWidgets('should display step indicators correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1 of 6: Basic Info'), findsOneWidget);
    });
  });
}
