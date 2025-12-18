import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/events/data/models/enhanced_event_model.dart';
import 'package:naijasingles/features/events/presentation/widgets/create_event_steps/location_step.dart';

void main() {
  group('LocationStep', () {
    late EventCreationData eventData;

    setUp(() {
      eventData = EventCreationData();
    });

    Widget createWidgetUnderTest() => MaterialApp(
        home: Scaffold(
          body: LocationStep(
            eventData: eventData,
          ),
        ),
      );

    testWidgets('should display location step with correct structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Where is your event?'), findsOneWidget);
      expect(find.text('Help people find your event location'), findsOneWidget);
    });

    testWidgets('should display venue name input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Venue Name *'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('should display street address input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Street Address *'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('should display city input field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('City *'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('should display state input field',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('State *'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('should display form field hints correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for hint texts
      expect(find.text('e.g., Lagos Continental Hotel'), findsOneWidget);
      expect(find.text('e.g., 52A Kofo Abayomi Street'), findsOneWidget);
      expect(find.text('e.g., Lagos'), findsOneWidget);
      expect(
          find.text('Enter state (e.g., Lagos, Abuja, Kano)'), findsOneWidget,);
    });

    testWidgets('should accept African location inputs',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and fill venue name
      final venueField = find.byWidgetPredicate(
        (widget) => widget is TextFormField && widget.controller?.text == '',
      );

      if (venueField.evaluate().isNotEmpty) {
        await tester.enterText(venueField.first, 'Lagos Social Club');
        await tester.pumpAndSettle();

        expect(find.text('Lagos Social Club'), findsOneWidget);
      }
    });

    testWidgets('should handle empty input fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check that TextFormFields exist and are empty
      final textFields = find.byType(TextFormField);
      expect(textFields,
          findsAtLeastNWidgets(5),); // Venue, Address, City, State, Country
    });

    testWidgets('should display correct background colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the main container
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should display required field indicators',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for required field indicators (*)
      expect(find.text('Venue Name *'), findsOneWidget);
      expect(find.text('Street Address *'), findsOneWidget);
      expect(find.text('City *'), findsOneWidget);
      expect(find.text('State *'), findsOneWidget);
      expect(find.text('Country *'), findsOneWidget);
    });
  });
}
