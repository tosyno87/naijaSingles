#!/usr/bin/env dart

import 'dart:io';
import 'package:naijasingles/services/test_data_generator_service.dart';

void main(List<String> arguments) async {
  print('🎯 Afropeep Test Data Manager');
  print('============================\n');

  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0];

  switch (command) {
    case 'generate':
      await _handleGenerateCommand(arguments);
      break;
    case 'cleanup':
      await _handleCleanupCommand();
      break;
    case 'stats':
      await _handleStatsCommand();
      break;
    case 'dry-run':
      await _handleDryRunCommand(arguments);
      break;
    default:
      print('❌ Unknown command: $command\n');
      _showHelp();
  }
}

void _showHelp() {
  print('Usage: dart test_data_manager.dart <command> [options]\n');
  print('Commands:');
  print('  generate [city] [count]  Generate test users');
  print('                           city: atlanta|miami|houston|all (default: all)');
  print('                           count: users per city (default: 20)');
  print('');
  print('  dry-run [city] [count]   Preview what users would be created');
  print('');
  print('  cleanup                  Delete all test users');
  print('');
  print('  stats                    Show test user statistics');
  print('');
  print('Examples:');
  print('  dart test_data_manager.dart generate all 30');
  print('  dart test_data_manager.dart generate miami 10');
  print('  dart test_data_manager.dart dry-run atlanta 20');
  print('  dart test_data_manager.dart cleanup');
  print('  dart test_data_manager.dart stats');
}

Future<void> _handleGenerateCommand(List<String> arguments) async {
  final city = arguments.length > 1 ? arguments[1] : 'all';
  final count = arguments.length > 2 ? int.tryParse(arguments[2]) ?? 20 : 20;

  print('🚀 Generating test users...');
  print('📍 City: $city');
  print('👥 Count: $count users per city\n');

  if (city == 'all') {
    await TestDataGeneratorService.generateAllTestUsers(
      usersPerCity: count,
      dryRun: false,
    );
  } else {
    await TestDataGeneratorService.generateTestUsersForCity(
      cityKey: city,
      maleCount: count ~/ 2,
      femaleCount: count ~/ 2,
      dryRun: false,
    );
  }

  print('\n✅ Test user generation completed!');
  print('💡 Run "dart test_data_manager.dart stats" to see the results');
}

Future<void> _handleDryRunCommand(List<String> arguments) async {
  final city = arguments.length > 1 ? arguments[1] : 'all';
  final count = arguments.length > 2 ? int.tryParse(arguments[2]) ?? 20 : 20;

  print('🔍 Dry run - Preview of test users to be created...');
  print('📍 City: $city');
  print('👥 Count: $count users per city\n');

  if (city == 'all') {
    await TestDataGeneratorService.generateAllTestUsers(
      usersPerCity: count,
      dryRun: true,
    );
  } else {
    await TestDataGeneratorService.generateTestUsersForCity(
      cityKey: city,
      maleCount: count ~/ 2,
      femaleCount: count ~/ 2,
      dryRun: true,
    );
  }

  print('\n💡 This was a dry run - no actual users were created');
  print('🚀 Run "dart test_data_manager.dart generate $city $count" to create them');
}

Future<void> _handleCleanupCommand() async {
  print('🧹 Cleaning up test users...\n');
  
  stdout.write('Are you sure you want to delete all test users? (y/N): ');
  final confirmation = stdin.readLineSync()?.toLowerCase();
  
  if (confirmation == 'y' || confirmation == 'yes') {
    await TestDataGeneratorService.cleanupTestUsers();
    print('\n✅ Test user cleanup completed!');
  } else {
    print('\n❌ Cleanup cancelled');
  }
}

Future<void> _handleStatsCommand() async {
  print('📊 Test User Statistics');
  print('======================\n');

  try {
    final stats = await TestDataGeneratorService.getTestUserStats();
    
    print('👥 Total Test Users: ${stats['totalTestUsers']}\n');
    
    print('👨👩 By Gender:');
    final genderStats = stats['byGender'] as Map<String, int>;
    genderStats.forEach((gender, count) {
      final emoji = gender == 'male' ? '👨' : '👩';
      print('  $emoji $gender: $count');
    });
    
    print('\n🏙️ By City:');
    final cityStats = stats['byCity'] as Map<String, int>;
    cityStats.forEach((city, count) {
      print('  📍 $city: $count');
    });
    
    print('\n📅 By Age Group:');
    final ageStats = stats['ageDistribution'] as Map<String, int>;
    ageStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))
      ..forEach((ageGroup, count) {
        print('  🎂 $ageGroup: $count');
      });
      
  } catch (e) {
    print('❌ Error getting statistics: $e');
    print('💡 Make sure Firebase is properly configured');
  }
}
