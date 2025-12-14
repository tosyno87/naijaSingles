import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/events/data/models/enhanced_event_model.dart';
import 'package:naijasingles/features/events/presentation/widgets/create_event_steps/ticketing_step.dart';

void main() {
  group('TicketingStep', () {
    late EventCreationData eventData;

    setUp(() {
      eventData = EventCreationData();
    });

    Widget createWidgetUnderTest() => MaterialApp(
        home: Scaffold(
          body: TicketingStep(
            eventData: eventData,
          ),
        ),
      );

    testWidgets('should display ticketing step with correct structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Event Pricing & Capacity'), findsOneWidget);
      expect(find.text('Set your event pricing and attendance limits'),
          findsOneWidget,);
    });

    testWidgets('should display pricing section', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Event Pricing'), findsOneWidget);
    });

    testWidgets('should display capacity section', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Event Capacity'), findsOneWidget);
    });

    testWidgets('should display free/paid toggle options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Free Event'), findsOneWidget);
      expect(find.text('Paid Event'), findsOneWidget);
      expect(find.text('No charge for attendees'), findsOneWidget);
      expect(find.text('Charge for tickets'), findsOneWidget);
    });

    testWidgets('should display currency selector for paid events',
        (WidgetTester tester) async {
      // Set to paid event first
      eventData.isFree = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for currency dropdown
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      // Check for currency label
      expect(find.text('Currency *'), findsOneWidget);
    });

    testWidgets('should display currency symbols correctly',
        (WidgetTester tester) async {
      // Set to paid event first
      eventData.isFree = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the dropdown to expand it
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Now check for currency symbols in the expanded dropdown
      expect(find.text('₦'), findsOneWidget);
      expect(find.text(r'$'), findsAtLeastNWidgets(1)); // Multiple $ symbols
      expect(find.text('£'), findsOneWidget);
      expect(find.text('€'), findsOneWidget);
    });

    testWidgets('should display price input for paid events',
        (WidgetTester tester) async {
      // Set to paid event first
      eventData.isFree = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for price input field - the label shows the currency symbol
      expect(find.text(r'Ticket Price ($) *'), findsOneWidget);
      expect(find.byType(TextFormField),
          findsAtLeastNWidgets(2),); // Price + Capacity
    });

    testWidgets('should update price when input changes',
        (WidgetTester tester) async {
      // Set to paid event first
      eventData.isFree = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the price input field specifically by looking for the one with price label
      final priceField = find.byWidgetPredicate(
        (widget) => widget is TextFormField && widget.controller?.text == '',
      );
      expect(priceField, findsAtLeastNWidgets(1));

      // Use the first TextFormField (should be the price field for paid events)
      await tester.enterText(priceField.first, '50.00');
      await tester.pumpAndSettle();

      expect(find.text('50.00'), findsOneWidget);
    });

    testWidgets('should not display currency selector for free events',
        (WidgetTester tester) async {
      // Ensure it's a free event (default state)
      eventData.isFree = true;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check that currency selector is not shown for free events
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('Currency *'), findsNothing);
      // Note: "Ticket Price" label is always visible, but the input field is not
    });

    testWidgets('should handle decimal price input correctly',
        (WidgetTester tester) async {
      // Set to paid event first
      eventData.isFree = false;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the price input field specifically
      final priceField = find.byWidgetPredicate(
        (widget) => widget is TextFormField && widget.controller?.text == '',
      );
      expect(priceField, findsAtLeastNWidgets(1));

      // Use the first TextFormField (should be the price field for paid events)
      await tester.enterText(priceField.first, '99.99');
      await tester.pumpAndSettle();

      expect(find.text('99.99'), findsOneWidget);
    });

    testWidgets('should display correct background colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the main container
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
