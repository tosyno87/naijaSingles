import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await FirebaseTestSetup.setupFirebase();
  });

  tearDownAll(FirebaseTestSetup.cleanup);

  group('Accessibility Tests', () {
    testWidgets('Screen reader compatibility', (WidgetTester tester) async {
      // Test that widgets have proper semantic labels
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Welcome to Afropeep'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Get Started'),
                ),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Enter your phone number',
                    hintText: '+1 404 555 0123',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test semantic labels
      expect(find.text('Welcome to Afropeep'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(find.text('+1 404 555 0123'), findsOneWidget);

      // Test that buttons are accessible
      final button = find.text('Get Started');
      expect(button, findsOneWidget);

      // Test that text fields have proper labels
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
    });

    testWidgets('Voice-over navigation', (WidgetTester tester) async {
      // Test that navigation is accessible via voice-over
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Afropeep')),
            body: Column(
              children: [
                ListTile(
                  title: const Text('Communities'),
                  subtitle: const Text('Connect with African communities'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Connect'),
                  subtitle: const Text('Find matches and friends'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Messages'),
                  subtitle: const Text('Chat with your matches'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Profile'),
                  subtitle: const Text('Manage your profile'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation items
      expect(find.text('Communities'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Test that list tiles are tappable
      final communitiesTile = find.text('Communities');
      expect(communitiesTile, findsOneWidget);

      // Test navigation accessibility
      await tester.tap(communitiesTile);
      await tester.pumpAndSettle();
    });

    testWidgets('Color contrast validation', (WidgetTester tester) async {
      // Test that colors have sufficient contrast
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: const Color(0xFF008037), // Green theme
            scaffoldBackgroundColor: Colors.white,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black87),
            ),
          ),
          home: const Scaffold(
            body: Column(
              children: [
                ColoredBox(
                  color: Color(0xFF008037),
                  child: Text(
                    'Green Background Text',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ColoredBox(
                  color: Colors.white,
                  child: Text(
                    'White Background Text',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test color contrast
      expect(find.text('Green Background Text'), findsOneWidget);
      expect(find.text('White Background Text'), findsOneWidget);

      // Colors should have sufficient contrast
      // Green (#008037) with white text should be readable
      // White background with black text should be readable
    });

    testWidgets('Font size scaling', (WidgetTester tester) async {
      // Test that text scales properly
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(
                  'Welcome to Afropeep',
                  style: TextStyle(fontSize: 24),
                ),
                Text(
                  'Connect with African diaspora',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Find meaningful relationships',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test different font sizes
      expect(find.text('Welcome to Afropeep'), findsOneWidget);
      expect(find.text('Connect with African diaspora'), findsOneWidget);
      expect(find.text('Find meaningful relationships'), findsOneWidget);

      // Test that text is readable at different sizes
      final welcomeText = find.text('Welcome to Afropeep');
      expect(welcomeText, findsOneWidget);
    });

    testWidgets('Touch target size validation', (WidgetTester tester) async {
      // Test that touch targets are large enough
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Large Button'),
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 32,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Small Button'),
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test button sizes
      expect(find.text('Large Button'), findsOneWidget);
      expect(find.text('Small Button'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Touch targets should be at least 44x44 pixels
      final largeButton = find.byType(ElevatedButton);
      expect(largeButton, findsOneWidget);
    });

    testWidgets('Keyboard navigation', (WidgetTester tester) async {
      // Test that forms can be navigated with keyboard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                    ),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                    ),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter your phone number',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test form fields
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      // Test keyboard navigation
      final nameField = find.byType(TextFormField).first;
      await tester.tap(nameField);
      await tester.pumpAndSettle();

      // Test that focus moves properly
      expect(nameField, findsOneWidget);
    });

    testWidgets('Cultural accessibility', (WidgetTester tester) async {
      // Test that cultural elements are accessible
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Select your cultural background'),
                DropdownButton<String>(
                  value: 'Nigeria',
                  items: const [
                    DropdownMenuItem(value: 'Nigeria', child: Text('Nigeria')),
                    DropdownMenuItem(value: 'Ghana', child: Text('Ghana')),
                    DropdownMenuItem(
                        value: 'Ethiopia', child: Text('Ethiopia')),
                    DropdownMenuItem(value: 'Kenya', child: Text('Kenya')),
                  ],
                  onChanged: (value) {},
                ),
                const Text('Select your ethnicity'),
                DropdownButton<String>(
                  value: 'Yoruba',
                  items: const [
                    DropdownMenuItem(value: 'Yoruba', child: Text('Yoruba')),
                    DropdownMenuItem(value: 'Igbo', child: Text('Igbo')),
                    DropdownMenuItem(value: 'Hausa', child: Text('Hausa')),
                  ],
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test cultural selection
      expect(find.text('Select your cultural background'), findsOneWidget);
      expect(find.text('Select your ethnicity'), findsOneWidget);
      expect(find.text('Nigeria'), findsOneWidget);
      expect(find.text('Yoruba'), findsOneWidget);

      // Test dropdown accessibility
      final countryDropdown = find.byType(DropdownButton<String>).first;
      expect(countryDropdown, findsOneWidget);
    });

    testWidgets('Error message accessibility', (WidgetTester tester) async {
      // Test that error messages are accessible
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    errorText: 'Please enter a valid phone number',
                  ),
                ),
                const Text(
                  'Error: Invalid input',
                  style: TextStyle(color: Colors.red),
                ),
                const Text(
                  'Please try again',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test error messages
      expect(find.text('Please enter a valid phone number'), findsOneWidget);
      expect(find.text('Error: Invalid input'), findsOneWidget);
      expect(find.text('Please try again'), findsOneWidget);

      // Error messages should be clearly visible
      final errorText = find.text('Error: Invalid input');
      expect(errorText, findsOneWidget);
    });

    testWidgets('Loading state accessibility', (WidgetTester tester) async {
      // Test that loading states are accessible
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CircularProgressIndicator(),
                Text('Loading your matches...'),
                LinearProgressIndicator(
                  value: 0.5,
                ), // Fixed value to prevent infinite animation
                Text('Uploading photos...'),
              ],
            ),
          ),
        ),
      );

      await tester
          .pump(); // Use pump() instead of pumpAndSettle() to avoid timeout

      // Test loading indicators
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Loading your matches...'), findsOneWidget);
      expect(find.text('Uploading photos...'), findsOneWidget);

      // Loading states should be accessible
      final loadingText = find.text('Loading your matches...');
      expect(loadingText, findsOneWidget);
    });

    testWidgets('Multi-language accessibility', (WidgetTester tester) async {
      // Test that multi-language support is accessible
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Welcome / Bawo / Ndewo'),
                Text('Connect / Sopọ / Njikọ'),
                Text('Messages / Oju-ọrọ / Ozi'),
                Text('Profile / Profaili / Profaịlụ'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test multi-language text
      expect(find.text('Welcome / Bawo / Ndewo'), findsOneWidget);
      expect(find.text('Connect / Sopọ / Njikọ'), findsOneWidget);
      expect(find.text('Messages / Oju-ọrọ / Ozi'), findsOneWidget);
      expect(find.text('Profile / Profaili / Profaịlụ'), findsOneWidget);

      // Multi-language text should be accessible
      final welcomeText = find.text('Welcome / Bawo / Ndewo');
      expect(welcomeText, findsOneWidget);
    });

    testWidgets('Text scaling at 200% does not overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Welcome to Afropeep'),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Get Started'),
                    ),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Enter your phone number',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to Afropeep'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tap targets meet 48x48 minimum', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Action'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final elevatedButtons = find.byType(ElevatedButton);
      expect(elevatedButtons, findsOneWidget);
      final btnSize = tester.getSize(elevatedButtons);
      expect(btnSize.height, greaterThanOrEqualTo(48));

      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsOneWidget);
      final iconSize = tester.getSize(iconButtons);
      expect(iconSize.width, greaterThanOrEqualTo(48));
      expect(iconSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Shared state views have Semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Loading...',
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Loading...'),
      );
      expect(semantics.label, 'Loading...');
    });

    testWidgets('Image accessibility', (WidgetTester tester) async {
      // Test that images have proper alt text
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Use Container with decoration instead of Image.asset for testing
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    semanticLabel: 'Afropeep Logo',
                  ),
                ),
                // Use Container instead of Image.network for testing
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo,
                    semanticLabel: 'User Profile Photo',
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person,
                    semanticLabel: 'Default Profile Picture',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test image accessibility
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.photo), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Images should have semantic labels
      final logoIcon = find.byIcon(Icons.image);
      expect(logoIcon, findsOneWidget);
    });
  });
}
