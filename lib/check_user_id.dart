import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'common/utils/app_logger.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CheckUserIdApp());
}

class CheckUserIdApp extends StatelessWidget {
  const CheckUserIdApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Check User ID'),
          ),
          body: Center(
            child: FutureBuilder<String?>(
              future: _getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final userId = snapshot.data;
                final testUserIds = ['test_user_1', 'test_user_2'];
                final matches = userId != null && testUserIds.contains(userId);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Current User ID:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userId ?? 'Not signed in',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Test User IDs:',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final testId in testUserIds)
                      Text(
                        testId,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      matches ? 'MATCH FOUND! ✅' : 'NO MATCH ❌',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: matches ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!matches && userId != null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Your current user ID does not match any of the test users in the imported data.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (userId == null)
                      ElevatedButton(
                        onPressed: _signInAnonymously,
                        child: const Text('Sign In Anonymously'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

  Future<String?> _getCurrentUserId() async {
    // Print to console for debugging
    final currentUser = FirebaseAuth.instance.currentUser;
    AppLogger.info('Current User ID: ${currentUser?.uid}');
    return currentUser?.uid;
  }

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on Object catch (e) {
      AppLogger.error('Error signing in', error: e);
    }
  }
}
