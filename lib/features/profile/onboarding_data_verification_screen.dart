import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/utils/app_logger.dart';
import '../../common/widgets/state_views/state_views.dart';

/// Screen to verify all onboarding data is properly saved and accessible
class OnboardingDataVerificationScreen extends StatefulWidget {
  const OnboardingDataVerificationScreen({super.key});

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
  String? _loadError;
  final List<String> _missingFields = [];
  final List<String> _presentFields = [];

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
    unawaited(_loadAndVerifyUserData());
  }

  Future<void> _loadAndVerifyUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _userData = null;
          _loadError = 'No authenticated user found.';
        });
        return;
      }

      AppLogger.debug('🔍 Loading user data for verification: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;

        // Verify which fields are present
        _presentFields.clear();
        _missingFields.clear();

        for (final field in _expectedFields) {
          if (data.containsKey(field) && data[field] != null) {
            // Check if field has meaningful data
            final value = data[field];
            var hasData = false;

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
          _loadError = null;
        });

        AppLogger.info('✅ Data verification complete');
        AppLogger.debug('   Present fields: $_presentFields');
        AppLogger.debug('   Missing fields: $_missingFields');
      } else {
        AppLogger.warning('❌ No user document found');
        setState(() {
          _userData = null;
          _isLoading = false;
          _loadError = null;
        });
      }
    } on Object catch (e) {
      AppLogger.error('❌ Error loading user data', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _userData = null;
        _loadError = 'Failed to load onboarding data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Onboarding Data Verification',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
        ),
        body: _isLoading
            ? const AppLoadingView(message: 'Loading onboarding data...')
            : _loadError != null
                ? AppErrorView(
                    title: 'Unable to verify onboarding data',
                    message: _loadError!,
                    onRetry: () {
                      unawaited(_loadAndVerifyUserData());
                    },
                  )
                : _userData == null
                    ? AppEmptyView(
                        title: 'No Onboarding Data Found',
                        subtitle: 'This user has no onboarding document yet.',
                        icon: Icons.description_outlined,
                        actionLabel: 'Refresh',
                        onAction: () {
                          unawaited(_loadAndVerifyUserData());
                        },
                      )
                    : SingleChildScrollView(
                        padding: AppSpacing.pagePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Card
                            _buildSummaryCard(),

                            const SizedBox(height: AppSpacing.md),

                            // Present Fields Card
                            _buildPresentFieldsCard(),

                            const SizedBox(height: AppSpacing.md),

                            // Missing Fields Card
                            _buildMissingFieldsCard(),

                            const SizedBox(height: AppSpacing.md),

                            // Raw Data Card
                            _buildRawDataCard(),

                            const SizedBox(height: AppSpacing.xl),

                            // Refresh Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  unawaited(_loadAndVerifyUserData());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Refresh Data',
                                  style: GoogleFonts.montserrat(
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

  Widget _buildSummaryCard() {
    final completionPercentage = _expectedFields.isEmpty
        ? 0.0
        : (_presentFields.length / _expectedFields.length) * 100;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Completeness Summary',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

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

            const SizedBox(height: AppSpacing.sm),

            Text(
              '${completionPercentage.toStringAsFixed(1)}% Complete',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: completionPercentage >= 80
                    ? Colors.green
                    : completionPercentage >= 50
                        ? Colors.orange
                        : Colors.red,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              '${_presentFields.length} of ${_expectedFields.length} fields present',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresentFieldsCard() => Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Present Fields (${_presentFields.length})',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (_presentFields.isEmpty)
                Text(
                  'No fields found',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _presentFields
                      .map(
                        (field) => Chip(
                          label: Text(
                            field,
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                          backgroundColor: Colors.green.shade100,
                          side: BorderSide(color: Colors.green.shade300),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      );

  Widget _buildMissingFieldsCard() => Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: AppSpacing.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Missing Fields (${_missingFields.length})',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (_missingFields.isEmpty)
                Text(
                  'All expected fields are present! 🎉',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _missingFields
                      .map(
                        (field) => Chip(
                          label: Text(
                            field,
                            style: GoogleFonts.montserrat(fontSize: 12),
                          ),
                          backgroundColor: Colors.red.shade100,
                          side: BorderSide(color: Colors.red.shade300),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      );

  Widget _buildRawDataCard() => Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sample Data Values',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (_userData == null)
                Text(
                  'No data available',
                  style: GoogleFonts.montserrat(
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
                    _buildDataRow(
                      'Bio Length',
                      '${(_userData!['bio'] ?? '').length} chars',
                    ),
                    _buildDataRow(
                      'Interests',
                      '${(_userData!['interests'] as List?)?.length ?? 0} items',
                    ),
                    _buildDataRow(
                      'Height',
                      _userData!['heightDisplay'] ?? _userData!['height_ft_in'],
                    ),
                    _buildDataRow('Looking For', _userData!['lookingFor']),
                    _buildDataRow(
                      'Relationship Intent',
                      _userData!['relationshipIntent'],
                    ),
                    _buildDataRow('Interested In', _userData!['interestedIn']),
                  ],
                ),
            ],
          ),
        ),
      );

  Widget _buildDataRow(String label, value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value?.toString() ?? 'null',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: value != null ? Colors.black87 : Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
}
