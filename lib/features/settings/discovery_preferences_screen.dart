import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/bloc/user/user_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';

class DiscoveryPreferencesScreen extends StatefulWidget {
  const DiscoveryPreferencesScreen({super.key});

  @override
  State<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends State<DiscoveryPreferencesScreen> {
  static const Color _primaryColor = AppColors.primaryGreen;
  static const Color _textPrimary = AppColors.textPrimary;
  static const Color _textSecondary = AppColors.textSecondary;

  bool _isLoading = true;
  String _showGender = 'everyone';
  double _maxDistance = 50;
  RangeValues _ageRange = const RangeValues(18, 50);

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _showGender = (data['showGender'] as String?) ?? 'everyone';
          _maxDistance = (data['maximum_distance'] as num?)?.toDouble() ?? 50;

          _ageRange = _parseAgeRange(data);
          _maxDistance = _maxDistance.clamp(1, 100);

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } on Object catch (e) {
      log('Error loading discovery preferences: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Extracts age range from Firestore data, clamping to slider bounds and
  /// ensuring start <= end so the RangeSlider never hits an assertion error.
  static RangeValues _parseAgeRange(Map<String, dynamic> data) {
    double lo = 18;
    double hi = 50;

    if (data['age_range'] is Map) {
      final ar = data['age_range'] as Map;
      lo = (int.tryParse(ar['min']?.toString() ?? '') ?? 18).toDouble();
      hi = (int.tryParse(ar['max']?.toString() ?? '') ?? 50).toDouble();
    } else if (data['preferences'] is Map &&
        (data['preferences'] as Map)['ageRange'] is List) {
      final list = (data['preferences'] as Map)['ageRange'] as List;
      if (list.length >= 2) {
        lo = (list[0] as num).toDouble();
        hi = (list[1] as num).toDouble();
      }
    }

    lo = lo.clamp(18, 80);
    hi = hi.clamp(18, 80);
    if (lo > hi) {
      final tmp = lo;
      lo = hi;
      hi = tmp;
    }

    return RangeValues(lo, hi);
  }

  Future<void> _savePreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'showGender': _showGender,
        'maximum_distance': _maxDistance.round(),
        'age_range': {
          'min': _ageRange.start.round().toString(),
          'max': _ageRange.end.round().toString(),
        },
      });

      if (!mounted) return;

      context.read<UserBloc>().add(const UserRefreshUserDetails());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preferences updated',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
      );
    } on Object catch (e) {
      log('Error saving discovery preferences: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save preferences',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: _textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Discovery Preferences',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _savePreferences,
              child: Text(
                'Save',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.contentInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShowMeSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDistanceSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildAgeRangeSection(),
                  ],
                ),
              ),
      );

  Widget _buildShowMeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show me',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGenderOption('Men', 'men', Icons.male),
          const SizedBox(height: 12),
          _buildGenderOption('Women', 'women', Icons.female),
          const SizedBox(height: 12),
          _buildGenderOption('Everyone', 'everyone', Icons.people),
        ],
      );

  Widget _buildGenderOption(String label, String value, IconData icon) {
    final isSelected = _showGender == value;

    return GestureDetector(
      onTap: () => setState(() => _showGender = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withValues(alpha: 0.08)
              : AppColors.overlayColor,
          border: Border.all(
            color: isSelected ? _primaryColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : _textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _primaryColor : _textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _primaryColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maximum distance',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _maxDistance.round() >= 100
                ? 'Anywhere'
                : '${_maxDistance.round()} miles',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: _primaryColor,
            inactiveColor: _primaryColor.withValues(alpha: 0.2),
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 mi',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                Text(
                  '100 mi',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildAgeRangeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Age range',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_ageRange.start.round()} – ${_ageRange.end.round()} years',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            activeColor: _primaryColor,
            inactiveColor: _primaryColor.withValues(alpha: 0.2),
            onChanged: (values) => setState(() => _ageRange = values),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '18',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                Text(
                  '80',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
