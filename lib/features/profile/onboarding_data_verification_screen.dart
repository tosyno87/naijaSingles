import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Screen to verify all onboarding data is properly saved and accessible
class OnboardingDataVerificationScreen extends StatefulWidget {
  const OnboardingDataVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingDataVerificationScreen> createState() =>
      _OnboardingDataVerificationScreenState();
}

class _OnboardingDataVerificationScreenState
    extends State<OnboardingDataVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  List<String> _missingFields = [];
  List<String> _presentFields = [];

  // Expected onboarding fields
  final List<String> _expectedFields = [
    'name',
    'dateOfBirth',
    'age',
    'gender',
    'tribe',
    'bio',
    'interests',
    'height',
    'height_ft_in',
    'height_cm',
    'heightDisplay',
    'lookingFor',
    'relationshipIntent',
    'interestedIn',
    'preferences',
    'photos',
  ];

  @override
  void initState() {
    super.initState();
    _loadAndVerifyUserData();
  }

  Future<void> _loadAndVerifyUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('🔍 Loading user data for verification: ${user.uid}');
        final doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data()!;

          // Verify which fields are present
          _presentFields.clear();
          _missingFields.clear();

          for (String field in _expectedFields) {
            if (data.containsKey(field) && data[field] != null) {
              // Check if field has meaningful data
              final value = data[field];
              bool hasData = false;

              if (value is String) {
                hasData = value.isNotEmpty;
              } else if (value is List) {
                hasData = value.isNotEmpty;
              } else if (value is Map) {
                hasData = value.isNotEmpty;
              } else if (value is num) {
                hasData = value > 0;
              } else {
                hasData = true; // Other types considered present
              }

              if (hasData) {
                _presentFields.add(field);
              } else {
                _missingFields.add('$field (empty)');
              }
            } else {
              _missingFields.add('$field (missing)');
            }
          }

          setState(() {
            _userData = data;
            _isLoading = false;
          });

          print('✅ Data verification complete');
          print('   Present fields: $_presentFields');
          print('   Missing fields: $_missingFields');
        } else {
          print('❌ No user document found');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF1E7),
      appBar: AppBar(
        title: Text(
          'Onboarding Data Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF008037),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  _buildSummaryCard(),

                  const SizedBox(height: 16),

                  // Present Fields Card
                  _buildPresentFieldsCard(),

                  const SizedBox(height: 16),

                  // Missing Fields Card
                  _buildMissingFieldsCard(),

                  const SizedBox(height: 16),

                  // Raw Data Card
                  _buildRawDataCard(),

                  const SizedBox(height: 32),

                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadAndVerifyUserData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008037),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Refresh Data',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final completionPercentage = _expectedFields.isEmpty
        ? 0.0
        : (_presentFields.length / _expectedFields.length) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Completeness Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPercentage >= 80
                    ? Colors.green
                    : completionPercentage >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${completionPercentage.toStringAsFixed(1)}% Complete',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: completionPercentage >= 80
                    ? Colors.green
                    : completionPercentage >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${_presentFields.length} of ${_expectedFields.length} fields present',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentFieldsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Present Fields (${_presentFields.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_presentFields.isEmpty)
              Text(
                'No fields found',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _presentFields.map((field) {
                  return Chip(
                    label: Text(
                      field,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    backgroundColor: Colors.green.shade100,
                    side: BorderSide(color: Colors.green.shade300),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingFieldsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Missing Fields (${_missingFields.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_missingFields.isEmpty)
              Text(
                'All expected fields are present! 🎉',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _missingFields.map((field) {
                  return Chip(
                    label: Text(
                      field,
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    backgroundColor: Colors.red.shade100,
                    side: BorderSide(color: Colors.red.shade300),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Data Values',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_userData == null)
              Text(
                'No data available',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataRow('Name', _userData!['name']),
                  _buildDataRow('Age', _userData!['age']),
                  _buildDataRow('Gender', _userData!['gender']),
                  _buildDataRow('Tribe', _userData!['tribe']),
                  _buildDataRow('Bio Length',
                      '${(_userData!['bio'] ?? '').length} chars'),
                  _buildDataRow('Interests',
                      '${(_userData!['interests'] as List?)?.length ?? 0} items'),
                  _buildDataRow(
                      'Height',
                      _userData!['heightDisplay'] ??
                          _userData!['height_ft_in']),
                  _buildDataRow('Looking For', _userData!['lookingFor']),
                  _buildDataRow(
                      'Relationship Intent', _userData!['relationshipIntent']),
                  _buildDataRow('Interested In', _userData!['interestedIn']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'null',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: value != null ? Colors.black87 : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
