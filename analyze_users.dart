import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naijasingles/firebase_options.dart';
import 'package:naijasingles/services/user_analytics_service.dart';
import 'package:naijasingles/debug/user_analysis_debug.dart';

Future<void> main() async {
  print('🚀 Starting user analysis...');

  try {
    // Initialize Flutter binding
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter binding initialized');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Run complete analysis
    await UserAnalysisDebug.runCompleteAnalysis();
  } catch (e) {
    print('❌ Error: $e');
  }
}
