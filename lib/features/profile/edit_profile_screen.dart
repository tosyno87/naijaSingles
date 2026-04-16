import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../common/constants/app_colors.dart';
import '../../common/constants/app_spacing.dart';
import '../../common/widgets/state_views/state_views.dart';
import '../../models/user_model.dart';
import '../discovery/presentation/screens/discovery_preferences_screen.dart';
import '../home/bloc/searchuser_bloc.dart';
import '../home/ui/screens/user_filter/bloc/userfilter_bloc.dart';
import '../onboarding/widgets/afropeep_height_dropdown.dart';

// Using centralized AppColors instead of local constants

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _otherTribeController = TextEditingController();

  // Selected values
  String _selectedGender = 'Male';
  DateTime? _selectedDOB;
  int _age = 0;
  String? _selectedTribe;

  // Track if user has completed onboarding (gender/age locked after first save)
  bool _hasCompletedOnboarding = false;

  // New fields
  String _heightFtIn = HeightData.defaultHeightFtIn;
  int _heightCm = HeightData.defaultHeightCm;
  String _relationshipIntent = 'Not sure yet';

  // Photos
  List<dynamic> _photos = List.filled(5, null); // Can be File or String (URL)
  bool _isUploading = false;
  bool _isInitialLoading = true;
  bool _loadError = false;
  bool _formValid = false;

  // Lists for dropdowns and selections
  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  final List<String> _tribes = [
    'Yoruba',
    'Igbo',
    'Hausa',
    'Fulani',
    'Edo',
    'Ijaw',
    'Kanuri',
    'Ibibio',
    'Tiv',
    'Efik',
    'Nupe',
    'Urhobo',
    'Igala',
    'Other',
  ];

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Firebase references
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Using centralized AppColors
  // backgroundColor = AppColors.backgroundColor
  // primaryColor = AppColors.primaryGreen
  // textColor = AppColors.textPrimary
  final Color errorColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();

    // Load existing user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadUserData());
    });

    // Add listener to bio text field to validate form
    _bioController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _otherTribeController.dispose();
    super.dispose();
  }

  void _validateForm() {
    if (!mounted) return;

    // Count valid photos
    final int photoCount = _photos.where((photo) => photo != null).length;

    // Check if all required fields are valid
    final bool isValid = _formKey.currentState?.validate() ?? false;

    // Check if user is 18+
    final bool isAdult = _age >= 18;

    // Check if bio is at least 20 characters (match registration requirement)
    final bool validBioLength = _bioController.text.trim().length >= 20;

    // Check if at least 3 photos are uploaded
    final bool hasEnoughPhotos = photoCount >= 3;

    setState(() {
      _formValid = isValid && isAdult && validBioLength && hasEnoughPhotos;
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isInitialLoading = true;
      _loadError = false;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loadError = true;
          _isInitialLoading = false;
        });
        return;
      }

      // Get user data from Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (docSnapshot.exists) {
        final userData = docSnapshot.data();
        if (userData == null) return;

        // Load basic info
        _nameController.text = userData['name'] ?? '';
        _bioController.text = userData['bio'] ?? '';

        // Load gender
        if (userData['gender'] != null) {
          setState(() {
            _selectedGender = userData['gender'];
          });
        }

        // Load DOB and calculate age
        if (userData['dateOfBirth'] != null) {
          setState(() {
            _selectedDOB = DateTime.parse(userData['dateOfBirth']);
            _calculateAge();
          });
        }

        // Prefer explicit completion flags over field-presence heuristics.
        _hasCompletedOnboarding = userData['onboardingCompleted'] == true ||
            userData['profileSetupComplete'] == true ||
            userData['isProfileComplete'] == true ||
            (userData['gender'] != null && userData['dateOfBirth'] != null);

        // Load tribe
        if (userData['tribe'] != null) {
          setState(() {
            _selectedTribe = userData['tribe'];
            final tribe = _selectedTribe;
            if (!_tribes.contains(tribe) && tribe != null) {
              _otherTribeController.text = tribe;
              _selectedTribe = 'Other';
            }
          });
        }

        // Load new fields
        if (userData['height'] != null) {
          setState(() {
            _heightCm = (userData['height'] as num).round();
            // Try to find matching ft/in value
            final String? ftIn = HeightData.getFtInFromCm(_heightCm);
            if (ftIn != null) {
              _heightFtIn = ftIn;
            }
          });
        }
        if (userData['relationshipIntent'] != null) {
          setState(() {
            _relationshipIntent = userData['relationshipIntent'];
          });
        } else if (userData['preferences'] is Map &&
            (userData['preferences'] as Map)['relationshipIntent'] != null) {
          setState(() {
            _relationshipIntent =
                (userData['preferences'] as Map)['relationshipIntent']
                    .toString();
          });
        }

        // Load photos with better error handling
        if (userData['photos'] != null && userData['photos'] is List) {
          final photoUrls = List<String>.from(userData['photos']);
          setState(() {
            // Clear existing photos first
            _photos = List.filled(5, null);
            // Load photos from URLs
            for (int i = 0; i < photoUrls.length && i < _photos.length; i++) {
              if (photoUrls[i].isNotEmpty) {
                _photos[i] = photoUrls[i];
              }
            }
          });
          log('Loaded ${photoUrls.length} photos from Firestore');
        }

      }

      // Validate form after loading data
      _validateForm();
    } on Object catch (e) {
      log('Error loading user data: $e');
      if (!mounted) return;
      setState(() {
        _loadError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  // Pick image for a specific slot
  Future<void> _pickImage(int index) async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();

      if (source == null) return;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _photos[index] = File(pickedFile.path);
          _validateForm();
        });
      }
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Show dialog to choose camera or gallery
  Future<ImageSource?> _showImageSourceDialog() async =>
      showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.chipRadius),
          ),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  // Build image source option labelLarge
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.buttonRadius,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: AppColors.primaryGreen),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  // Remove photo from a specific slot
  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;

      // Shift photos to fill the gap
      final List<dynamic> newPhotos = List.filled(5, null);
      int newIndex = 0;

      for (var photo in _photos) {
        if (photo != null && newIndex < newPhotos.length) {
          newPhotos[newIndex] = photo;
          newIndex++;
        }
      }

      _photos = newPhotos;
      _validateForm();
    });
  }

  Future<void> _showDeleteDialog(int index) async => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            'Remove Photo',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to remove this photo?',
            style: GoogleFonts.montserrat(
              color: AppColors.textPrimary,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey.shade700,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Remove',
                style: GoogleFonts.montserrat(
                  color: errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                _removePhoto(index);
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
        ),
      );

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isUploading = true);
    var saveStage = 'validate_form';

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify user is still authenticated
      saveStage = 'auth_reload';
      await user.reload();
      if (_auth.currentUser == null) {
        throw Exception('Authentication expired. Please log in again.');
      }

      // Upload photos if they are File objects
      final List<String> photoUrls = [];

      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];

        if (photo == null) continue;

        if (photo is File) {
          // Upload new photo - path must match Firebase Storage rules
          try {
            saveStage = 'upload_photo_$i';
            final ref =
                _storage.ref().child('profile_photos/${user.uid}/photo_$i.jpg');
            await ref.putFile(photo);
            final url = await ref.getDownloadURL();
            photoUrls.add(url);
            log('Successfully uploaded photo $i to: profile_photos/${user.uid}/photo_$i.jpg');
          } on Object catch (storageError) {
            log('Storage upload error for photo $i: $storageError');
            throw Exception('Failed to upload photo ${i + 1}: $storageError');
          }
        } else if (photo is String) {
          // Keep existing photo URL
          photoUrls.add(photo);
        }
      }

      // Merge `preferences` with Firestore so discovery-only keys
      // (ageRange, interestedIn, lookingFor, etc.) are not overwritten here.
      final DocumentSnapshot<Map<String, dynamic>> latestDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final Map<String, dynamic> mergedPreferences = <String, dynamic>{};
      final Object? prefsRaw = latestDoc.data()?['preferences'];
      if (prefsRaw is Map) {
        mergedPreferences.addAll(
          Map<String, dynamic>.from(
            prefsRaw.map(
              (Object? k, Object? v) => MapEntry(k.toString(), v),
            ),
          ),
        );
      }
      mergedPreferences['relationshipIntent'] = _relationshipIntent;

      // Create user data map — exclude identity fields that the server
      // locks after onboarding so we never trip the Firestore rule or
      // risk a format-mismatch comparison blocking a legitimate save.
      final Map<String, dynamic> userData = {
        'bio': _bioController.text.trim(),
        'tribe': _selectedTribe == 'Other'
            ? _otherTribeController.text.trim()
            : _selectedTribe,
        'photos': photoUrls,
        'height': _heightCm,
        'height_ft_in': _heightFtIn,
        'height_cm': _heightCm,
        'heightDisplay': _heightFtIn,
        'relationshipIntent': _relationshipIntent,
        'preferences': mergedPreferences,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      if (!_hasCompletedOnboarding) {
        userData['name'] = _nameController.text.trim();
        userData['gender'] = _selectedGender;
        userData['dateOfBirth'] = _selectedDOB?.toIso8601String();
        userData['age'] = _age;
      }

      // Update Firestore
      saveStage = 'update_firestore';
      await _firestore.collection('users').doc(user.uid).update(userData);

      // Update display name in Firebase Auth
      saveStage = 'update_auth_display_name';
      await user.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back with success indicator
      Navigator.pop(context, true);
    } on FirebaseException catch (e, stackTrace) {
      log(
        'Firebase error saving profile at stage=$saveStage, code=${e.code}, message=${e.message}, userId=${_auth.currentUser?.uid}',
        stackTrace: stackTrace,
      );
      await _recordProfileUpdateFailure(
        stage: saveStage,
        errorType: 'firebase_${e.plugin}',
        errorMessage: e.message ?? e.code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    } on Object catch (e) {
      log(
        'Error saving profile at stage=$saveStage, userId=${_auth.currentUser?.uid}, error=$e',
      );
      await _recordProfileUpdateFailure(
        stage: saveStage,
        errorType: 'unknown',
        errorMessage: e.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _openDatingPreferences() async {
    final User? authUser = _auth.currentUser;
    if (authUser == null) return;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(authUser.uid).get();
    if (!mounted || !doc.exists) return;
    final UserModel currentUser = UserModel.fromDocument(doc);
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => BlocProvider<UserfilterBloc>(
          create: (_) => UserfilterBloc(),
          child: BlocProvider<SearchUserBloc>(
            create: (_) => SearchUserBloc(),
            child: DiscoveryPreferencesScreen(
              currentUser: currentUser,
              isPurchased: currentUser.hasPremiumAccess,
              items: const <String, dynamic>{},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordProfileUpdateFailure({
    required String stage,
    required String errorType,
    required String errorMessage,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('private')
          .doc('profile_update_logs')
          .collection('entries')
          .add({
        'stage': stage,
        'errorType': errorType,
        'errorMessage': errorMessage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on Object catch (logError) {
      log('Failed to persist profile update diagnostics: $logError');
    }
  }

  Widget _buildDateOfBirthSelector() => InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDOB ??
                DateTime.now().subtract(const Duration(days: 365 * 25)),
            firstDate: DateTime(1950),
            lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryGreen,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            ),
          );

          if (picked != null && picked != _selectedDOB) {
            setState(() {
              _selectedDOB = picked;
              _calculateAge();
              _validateForm();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
              const SizedBox(width: AppSpacing.buttonRadius),
              Expanded(
                child: Text(
                  _selectedDOB != null
                      ? DateFormat('MMMM d, yyyy').format(_selectedDOB!)
                      : 'Select your date of birth',
                  style: GoogleFonts.montserrat(
                    color: _selectedDOB != null
                        ? AppColors.textPrimary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              if (_selectedDOB != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Text(
                    '$_age years',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildBioField() {
    const int maxLength = 500; // Match registration max length
    final int currentLength = _bioController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _bioController,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            maxLines: 8, // Match registration max lines
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: 'Write your bio here...', // Match registration hint
              hintStyle: GoogleFonts.montserrat(
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                borderSide:
                    const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
              contentPadding: AppSpacing.cardPadding,
              counterText: '', // Hide default counter
            ),
            onChanged: (value) {
              setState(() {}); // Update character counter
              _validateForm(); // Validate form
            },
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Minimum 20 characters', // Match registration requirement
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color:
                    currentLength >= 20 ? AppColors.primaryGreen : Colors.grey,
              ),
            ),
            Text(
              '$currentLength/$maxLength',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color:
                    currentLength >= 20 ? AppColors.primaryGreen : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Validation message
        if (currentLength > 0 && currentLength < 20)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Bio should be at least 20 characters',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? helperText,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.montserrat(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade700),
          helperText: helperText,
          helperStyle: GoogleFonts.montserrat(fontSize: 12),
          prefixIcon: Icon(prefixIcon, color: AppColors.primaryGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            borderSide:
                const BorderSide(color: AppColors.primaryGreen, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
        onChanged: (_) => _validateForm(),
      );

  Widget _buildReadOnlyField(String value, IconData icon) => Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border:
              Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryGreen.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: AppSpacing.buttonRadius),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryGreen,
                    size: 12,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Set',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
      );

  void _calculateAge() {
    final dob = _selectedDOB;
    if (dob != null) {
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      setState(() {
        _age = age;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isInitialLoading
            ? const AppLoadingView()
            : _loadError
                ? AppErrorView(
                    message: 'Unable to load profile',
                    onRetry: () => unawaited(_loadUserData()),
                  )
                : Stack(
                    children: [
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          padding: AppSpacing.pagePadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photos section
                              _buildSectionTitle('Profile Photos (Min. 3)'),
                              const SizedBox(height: AppSpacing.sm),
                              _buildPhotoGrid(),

                              if (_photos.where((p) => p != null).length < 3)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    'Please upload at least 3 photos',
                                    style: GoogleFonts.montserrat(
                                      color: errorColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.lg),

                              _buildSectionTitle('Basic Information'),
                              const SizedBox(height: AppSpacing.md),

                              // Name field
                              if (_hasCompletedOnboarding)
                                _buildReadOnlyField(
                                  _nameController.text,
                                  Icons.person,
                                )
                              else
                                _buildTextField(
                                  controller: _nameController,
                                  labelText: 'Full Name',
                                  prefixIcon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: AppSpacing.md),

                              _buildBioField(),
                              const SizedBox(height: AppSpacing.md),

                              _buildSectionTitle('Gender'),
                              const SizedBox(height: AppSpacing.sm),
                              if (_hasCompletedOnboarding)
                                _buildReadOnlyField(
                                  _selectedGender,
                                  Icons.person_outline,
                                )
                              else
                                _buildGenderSelector(),
                              const SizedBox(height: AppSpacing.lg),

                              _buildSectionTitle('Date of Birth'),
                              const SizedBox(height: AppSpacing.sm),
                              if (_hasCompletedOnboarding)
                                _buildReadOnlyField(
                                  _selectedDOB != null
                                      ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year} ($_age years old)'
                                      : 'Not set',
                                  Icons.cake_outlined,
                                )
                              else
                                _buildDateOfBirthSelector(),
                              const SizedBox(height: AppSpacing.lg),

                              _buildSectionTitle('Tribe/Ethnicity (Optional)'),
                              const SizedBox(height: AppSpacing.sm),
                              if (_hasCompletedOnboarding)
                                _buildReadOnlyField(
                                  _selectedTribe == 'Other'
                                      ? _otherTribeController.text.isNotEmpty
                                          ? _otherTribeController.text
                                          : 'Other'
                                      : _selectedTribe ?? 'Not specified',
                                  Icons.people_outline,
                                )
                              else
                                _buildTribeSelector(),
                              const SizedBox(height: AppSpacing.lg),

                              _buildSectionTitle('Height'),
                              const SizedBox(height: AppSpacing.md),
                              AfropeepHeightDropdown(
                                initialHeightFtIn: _heightFtIn,
                                initialHeightCm: _heightCm,
                                onChanged: (heightFtIn, heightCm) {
                                  setState(() {
                                    _heightFtIn = heightFtIn;
                                    _heightCm = heightCm;
                                    _validateForm(); // Add form validation trigger
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              _buildSectionTitle('Preferences'),
                              const SizedBox(height: AppSpacing.md),
                              InkWell(
                                onTap: () => unawaited(_openDatingPreferences()),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.buttonRadius,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius,
                                    ),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.tune,
                                        color: AppColors.primaryGreen,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Dating preferences',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Distance, age, who you see, and more',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Save button with better visibility and feedback
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _formValid
                                          ? AppColors.primaryGreen
                                              .withValues(alpha: 0.3)
                                          : Colors.grey.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _formValid ? _saveProfile : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _formValid
                                        ? AppColors.primaryGreen
                                        : Colors.grey.shade400,
                                    disabledBackgroundColor:
                                        Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                    elevation: 0, // Using custom shadow instead
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _formValid ? Icons.save : Icons.lock,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formValid
                                            ? 'Save Profile'
                                            : 'Complete Required Fields',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Form validation status
                              if (!_formValid) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: AppSpacing.cardPadding,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius,
                                    ),
                                    border: Border.all(
                                      color:
                                          Colors.orange.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            'Complete these requirements to save:',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildValidationRequirements(),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                      if (_isUploading)
                        ColoredBox(
                          color: Colors.black.withValues(alpha: 0.3),
                          child: const Center(child: AppLoadingView()),
                        ),
                    ],
                  ),
      );

  Widget _buildPhotoGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: 5, // Maximum 5 photos
        itemBuilder: (context, index) {
          final photo = _photos[index];

          return GestureDetector(
            onTap: () => _pickImage(index),
            onLongPress: photo != null ? () => _showDeleteDialog(index) : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: photo == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: AppColors.primaryGreen.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                          child: photo is File
                              ? Image.file(
                                  photo,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: photo,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => ColoredBox(
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primaryGreen,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    log('Error loading image: $error');
                                    return ColoredBox(
                                      color: Colors.grey.shade200,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.grey.shade500,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Failed to load',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () => _removePhoto(index),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      );

  Widget _buildGenderSelector() => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _genders.map((gender) {
          final isSelected = _selectedGender == gender;

          return ChoiceChip(
            label: Text(
              gender,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primaryGreen,
            backgroundColor: AppColors.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              side: BorderSide(
                color:
                    isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
              ),
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedGender = gender;
                  _validateForm();
                });
              }
            },
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          );
        }).toList(),
      );

  Widget _buildTribeSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedTribe,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.buttonRadius,
                ),
                hintText: 'Select your tribe/ethnicity (optional)',
                hintStyle: GoogleFonts.montserrat(color: Colors.grey.shade600),
                prefixIcon:
                    const Icon(Icons.people, color: AppColors.primaryGreen),
              ),
              items: _tribes
                  .map(
                    (tribe) => DropdownMenuItem<String>(
                      value: tribe,
                      child: Text(
                        tribe,
                        style: GoogleFonts.montserrat(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTribe = value;
                  _validateForm();
                });
              },
              validator: (value) => null,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primaryGreen,
              ),
              dropdownColor: Colors.white,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (_selectedTribe == 'Other') ...[
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _otherTribeController,
              decoration: InputDecoration(
                labelText: 'Specify your tribe/ethnicity',
                labelStyle: GoogleFonts.montserrat(color: Colors.grey.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: GoogleFonts.montserrat(),
              validator: (value) => null,
              onChanged: (_) => _validateForm(),
            ),
          ],
        ],
      );

  Widget _buildValidationRequirements() {
    final List<Widget> requirements = [];

    // Check photo count
    final int photoCount = _photos.where((photo) => photo != null).length;
    if (photoCount < 3) {
      requirements.add(
        _buildRequirementItem(
          'Upload at least 3 photos',
          Icons.photo_camera,
          photoCount >= 3,
        ),
      );
    }

    // Check bio length
    final bool validBioLength = _bioController.text.trim().length >= 20;
    if (!validBioLength) {
      requirements.add(
        _buildRequirementItem(
          'Write a bio (minimum 20 characters)',
          Icons.description,
          validBioLength,
        ),
      );
    }

    // Check age
    final bool isAdult = _age >= 18;
    if (!isAdult) {
      requirements.add(
        _buildRequirementItem(
          'You must be 18+ years old',
          Icons.cake,
          isAdult,
        ),
      );
    }

    // Check form validation
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      requirements.add(
        _buildRequirementItem(
          'Complete all required fields',
          Icons.check_circle,
          formValid,
        ),
      );
    }

    return Column(
      children: requirements,
    );
  }

  Widget _buildRequirementItem(String text, IconData icon, bool isCompleted) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : icon,
              color: isCompleted ? Colors.green : Colors.orange.shade700,
              size: AppSpacing.md,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
}
