import 'package:flutter/material.dart';
import 'package:naijasingles/services/test_data_generator_service.dart';

class TestDataManagementScreen extends StatefulWidget {
  const TestDataManagementScreen({Key? key}) : super(key: key);

  @override
  State<TestDataManagementScreen> createState() =>
      _TestDataManagementScreenState();
}

class _TestDataManagementScreenState extends State<TestDataManagementScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await TestDataGeneratorService.getTestUserStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTestUsers({
    required String city,
    required int count,
    bool dryRun = false,
  }) async {
    setState(() {
      _isLoading = true;
      _statusMessage =
          dryRun ? 'Previewing test users...' : 'Generating test users...';
    });

    try {
      if (city == 'all') {
        await TestDataGeneratorService.generateAllTestUsers(
          usersPerCity: count,
          dryRun: dryRun,
        );
      } else {
        await TestDataGeneratorService.generateTestUsersForCity(
          cityKey: city,
          maleCount: count ~/ 2,
          femaleCount: count ~/ 2,
          dryRun: dryRun,
        );
      }

      setState(() {
        _statusMessage = dryRun
            ? 'Dry run completed - no users created'
            : 'Test users generated successfully!';
        _isLoading = false;
      });

      if (!dryRun) {
        await _loadStats(); // Refresh stats
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupTestUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cleanup'),
        content: const Text(
          'This will delete ALL test users. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Cleaning up test users...';
      });

      try {
        await TestDataGeneratorService.cleanupTestUsers();
        setState(() {
          _statusMessage = 'Test users cleaned up successfully!';
          _isLoading = false;
        });
        await _loadStats(); // Refresh stats
      } catch (e) {
        setState(() {
          _statusMessage = 'Error during cleanup: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Management'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Message
                  if (_statusMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusMessage!.contains('Error')
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _statusMessage!.contains('Error')
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.contains('Error')
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Statistics Section
                  if (_stats != null) ...[
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Quick Actions
                  _buildQuickActionsSection(),

                  const SizedBox(height: 24),

                  // City-specific Generation
                  _buildCityGenerationSection(),

                  const SizedBox(height: 24),

                  // Cleanup Section
                  _buildCleanupSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats!;
    final totalUsers = stats['totalTestUsers'] as int;
    final genderStats = stats['byGender'] as Map<String, int>;
    final cityStats = stats['byCity'] as Map<String, int>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Test User Statistics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Users
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Test Users:'),
                Chip(
                  label: Text('$totalUsers'),
                  backgroundColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Gender Distribution
            const Text('Gender Distribution:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...genderStats.entries.map((entry) {
              final emoji = entry.key == 'male' ? '👨' : '👩';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$emoji ${entry.key.capitalize()}:'),
                    Text('${entry.value}'),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),

            // City Distribution
            const Text('City Distribution:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...cityStats.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('📍 ${entry.key}:'),
                          Text('${entry.value}'),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _generateTestUsers(
                              city: 'all',
                              count: 20,
                              dryRun: true,
                            ),
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _generateTestUsers(
                              city: 'all',
                              count: 20,
                            ),
                    icon: const Icon(Icons.add),
                    label: const Text('Generate All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityGenerationSection() {
    final cities = [
      {'key': 'atlanta', 'name': 'Atlanta, GA', 'emoji': '🏙️'},
      {'key': 'miami', 'name': 'Miami, FL', 'emoji': '🏖️'},
      {'key': 'houston', 'name': 'Houston, TX', 'emoji': '🚀'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_city, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'City-Specific Generation',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...cities
                .map((city) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('${city['emoji']} ${city['name']}'),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _generateTestUsers(
                                      city: city['key']!,
                                      count: 20,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade100,
                              foregroundColor: Colors.purple,
                            ),
                            child: const Text('Generate 20'),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_forever, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Cleanup',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Remove all test users from the database. This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cleanupTestUsers,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete All Test Users'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
