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

  // Print the current user ID
  final currentUser = FirebaseAuth.instance.currentUser;
  AppLogger.info('Current User ID: ${currentUser?.uid}');

  // Check if it matches test users
  final testUserIds = ['test_user_1', 'test_user_2'];
  final matches = currentUser != null && testUserIds.contains(currentUser.uid);

  AppLogger.info('Test User IDs: $testUserIds');
  AppLogger.info(matches ? 'MATCH FOUND! ✅' : 'NO MATCH ❌');

  // Exit the app after printing
  runApp(const PrintUserIdApp());
}

class PrintUserIdApp extends StatelessWidget {
  const PrintUserIdApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('User ID Check'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Check the console output',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text(
                  'Current User ID: ${FirebaseAuth.instance.currentUser?.uid ?? 'Not signed in'}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
}
