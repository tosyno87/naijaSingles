import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:developer';
import '../onboarding/widgets/afropeep_height_dropdown.dart';

// Color constants to match registration screens
const Color primaryColor = Color(0xFF008037); // Deep green
const Color textColor = Color(0xFF333333); // Dark text

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

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

  // Preference values
  String _interestedIn = 'Female';
  RangeValues _ageRange = const RangeValues(18, 35);

  // New fields
  String _heightFtIn = HeightData.defaultHeightFtIn;
  int _heightCm = HeightData.defaultHeightCm;
  String _lookingFor = 'Dating';
  String _relationshipIntent = 'Not sure yet';

  // Photos
  List<dynamic> _photos = List.filled(5, null); // Can be File or String (URL)
  bool _isUploading = false;
  bool _formValid = false;

  // Lists for dropdowns and selections
  final List<String> _genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];
  final List<String> _interestedInOptions = ['Male', 'Female', 'Everyone'];

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
    'Other'
  ];

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Firebase references
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Define colors based on Afropeep MVP
  final Color backgroundColor = const Color(0xFFFDF1E7); // Cream background
  final Color primaryColor = const Color(0xFF008037); // Afropeep green
  final Color textColor = Colors.black87;
  final Color errorColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();

    // Load existing user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
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
    int photoCount = _photos.where((photo) => photo != null).length;

    // Check if all required fields are valid
    bool isValid = _formKey.currentState?.validate() ?? false;

    // Check if user is 18+
    bool isAdult = _age >= 18;

    // Check if bio is at least 20 characters (match registration requirement)
    bool validBioLength = _bioController.text.trim().length >= 20;

    // Check if at least 3 photos are uploaded
    bool hasEnoughPhotos = photoCount >= 3;

    setState(() {
      _formValid = isValid && isAdult && validBioLength && hasEnoughPhotos;
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Get user data from Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        final userData = docSnapshot.data()!;

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

        // Check if user has completed onboarding (has gender, DOB, and tribe)
        _hasCompletedOnboarding = userData['gender'] != null &&
            userData['dateOfBirth'] != null &&
            userData['tribe'] != null;

        // Load tribe
        if (userData['tribe'] != null) {
          setState(() {
            _selectedTribe = userData['tribe'];
            if (!_tribes.contains(_selectedTribe) && _selectedTribe != null) {
              _otherTribeController.text = _selectedTribe!;
              _selectedTribe = 'Other';
            }
          });
        }

        // Load new fields
        if (userData['height'] != null) {
          setState(() {
            _heightCm = (userData['height'] as num).round();
            // Try to find matching ft/in value
            String? ftIn = HeightData.getFtInFromCm(_heightCm);
            if (ftIn != null) {
              _heightFtIn = ftIn;
            }
          });
        }
        if (userData['lookingFor'] != null) {
          setState(() {
            _lookingFor = userData['lookingFor'];
          });
        }
        if (userData['relationshipIntent'] != null) {
          setState(() {
            _relationshipIntent = userData['relationshipIntent'];
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

        // Load preferences
        if (userData['preferences'] != null) {
          final prefs = userData['preferences'];

          if (prefs['interestedIn'] != null) {
            setState(() {
              _interestedIn = prefs['interestedIn'];
            });
          }

          if (prefs['ageRange'] != null && prefs['ageRange'] is List) {
            final range = List<int>.from(prefs['ageRange']);
            if (range.length == 2) {
              setState(() {
                _ageRange =
                    RangeValues(range[0].toDouble(), range[1].toDouble());
              });
            }
          }
        }
      }

      // Validate form after loading data
      _validateForm();
    } catch (e) {
      log('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
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
        setState(() {
          _photos[index] = File(pickedFile.path);
          _validateForm();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Show dialog to choose camera or gallery
  Future<ImageSource?> _showImageSourceDialog() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
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
  }

  // Build image source option labelLarge
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _showDeleteDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove Photo',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: Text(
            'Are you sure you want to remove this photo?',
            style: GoogleFonts.poppins(
              color: textColor,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
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
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Verify user is still authenticated
      await user.reload();
      if (_auth.currentUser == null) {
        throw Exception('Authentication expired. Please log in again.');
      }

      // Upload photos if they are File objects
      List<String> photoUrls = [];

      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];

        if (photo == null) continue;

        if (photo is File) {
          // Upload new photo - path must match Firebase Storage rules
          try {
            final ref =
                _storage.ref().child('profile_photos/${user.uid}/photo_$i.jpg');
            final uploadTask = await ref.putFile(photo);
            final url = await ref.getDownloadURL();
            photoUrls.add(url);
            log('Successfully uploaded photo $i to: profile_photos/${user.uid}/photo_$i.jpg');
          } catch (storageError) {
            log('Storage upload error for photo $i: $storageError');
            throw Exception('Failed to upload photo ${i + 1}: $storageError');
          }
        } else if (photo is String) {
          // Keep existing photo URL
          photoUrls.add(photo);
        }
      }

      // Create user data map
      final Map<String, dynamic> userData = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _selectedDOB?.toIso8601String(),
        'age': _age,
        'tribe': _selectedTribe == 'Other'
            ? _otherTribeController.text.trim()
            : _selectedTribe,
        'photos': photoUrls,
        'height': _heightCm,
        'height_ft_in': _heightFtIn,
        'height_cm': _heightCm,
        'heightDisplay': _heightFtIn,
        'lookingFor': _lookingFor,
        'relationshipIntent': _relationshipIntent,
        'preferences': {
          'interestedIn': _interestedIn,
          'ageRange': [_ageRange.start.round(), _ageRange.end.round()],
          'lookingFor': _lookingFor,
          'relationshipIntent': _relationshipIntent,
        },
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update(userData);

      // Update display name in Firebase Auth
      await user.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back with success indicator
      Navigator.pop(context, true);
    } catch (e) {
      log('Error saving profile: $e');
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

  Widget _buildInterestedInSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interested In',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestedInOptions.map((option) {
            final isSelected = _interestedIn == option;

            return ChoiceChip(
              label: Text(
                option,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : textColor,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _interestedIn = option;
                  });
                }
              },
              elevation: isSelected ? 2 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthSelector() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDOB ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1950),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: textColor,
                ),
              ),
              child: child!,
            );
          },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Icon(Icons.calendar_today, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDOB != null
                    ? DateFormat('MMMM d, yyyy').format(_selectedDOB!)
                    : 'Select your date of birth',
                style: GoogleFonts.poppins(
                  color:
                      _selectedDOB != null ? textColor : Colors.grey.shade600,
                ),
              ),
            ),
            if (_selectedDOB != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_age years',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBioField() {
    const int maxLength = 500; // Match registration max length
    final int currentLength = _bioController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Me',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),

        // Bio input container - match registration styling
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textColor,
            ),
            maxLines: 8, // Match registration max lines
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: "Write your bio here...", // Match registration hint
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              counterText: "", // Hide default counter
            ),
            onChanged: (value) {
              setState(() {}); // Update character counter
              _validateForm(); // Validate form
            },
          ),
        ),

        const SizedBox(height: 8),

        // Custom character counter - match registration styling
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Minimum 20 characters", // Match registration requirement
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: currentLength >= 20 ? primaryColor : Colors.grey,
              ),
            ),
            Text(
              "$currentLength/$maxLength",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: currentLength >= 20 ? primaryColor : Colors.grey,
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
              "Bio should be at least 20 characters",
              style: GoogleFonts.poppins(
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
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.poppins(color: textColor),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
        helperText: helperText,
        helperStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(prefixIcon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      onChanged: (_) => _validateForm(),
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: primaryColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Set',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }

  void _calculateAge() {
    if (_selectedDOB != null) {
      final now = DateTime.now();
      int age = now.year - _selectedDOB!.year;
      if (now.month < _selectedDOB!.month ||
          (now.month == _selectedDOB!.month && now.day < _selectedDOB!.day)) {
        age--;
      }
      setState(() {
        _age = age;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Updating profile...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos section
                    _buildSectionTitle('Profile Photos (Min. 3)'),
                    const SizedBox(height: 8),
                    _buildPhotoGrid(),

                    // Photo count warning if needed
                    if (_photos.where((p) => p != null).length < 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please upload at least 3 photos',
                          style: GoogleFonts.poppins(
                            color: errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Basic info section
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 16),

                    // Name field
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
                    const SizedBox(height: 16),

                    // Bio field - Custom implementation to match registration
                    _buildBioField(),
                    const SizedBox(height: 16),

                    // Gender selection - only editable during onboarding
                    _buildSectionTitle('Gender'),
                    const SizedBox(height: 8),
                    _hasCompletedOnboarding
                        ? _buildReadOnlyField(
                            _selectedGender, Icons.person_outline)
                        : _buildGenderSelector(),
                    const SizedBox(height: 24),

                    // Date of Birth - only editable during onboarding
                    _buildSectionTitle('Date of Birth'),
                    const SizedBox(height: 8),
                    _hasCompletedOnboarding
                        ? _buildReadOnlyField(
                            _selectedDOB != null
                                ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year} ($_age years old)'
                                : 'Not set',
                            Icons.cake_outlined)
                        : _buildDateOfBirthSelector(),
                    const SizedBox(height: 24),

                    // Tribe selection - only editable during onboarding
                    _buildSectionTitle('Tribe/Ethnicity'),
                    const SizedBox(height: 8),
                    _hasCompletedOnboarding
                        ? _buildReadOnlyField(
                            _selectedTribe == 'Other'
                                ? _otherTribeController.text.isNotEmpty
                                    ? _otherTribeController.text
                                    : 'Other'
                                : _selectedTribe ?? 'Not specified',
                            Icons.people_outline)
                        : _buildTribeSelector(),
                    const SizedBox(height: 24),

                    // Height section
                    _buildSectionTitle('Height'),
                    const SizedBox(height: 16),
                    AfropeepHeightDropdown(
                      initialHeightFtIn: _heightFtIn,
                      initialHeightCm: _heightCm,
                      onChanged: (heightFtIn, heightCm) {
                        setState(() {
                          _heightFtIn = heightFtIn;
                          _heightCm = heightCm;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Preferences section
                    _buildSectionTitle('Preferences'),
                    const SizedBox(height: 16),

                    // Interested in
                    _buildInterestedInSelector(),
                    const SizedBox(height: 16),

                    // Age range
                    _buildAgeRangeSelector(),
                    const SizedBox(height: 32),

                    // Save labelLarge
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _formValid ? _saveProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Save Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 5, // Maximum 5 photos
      itemBuilder: (context, index) {
        final photo = _photos[index];

        return GestureDetector(
          onTap: () => _pickImage(index),
          onLongPress: photo != null ? () => _showDeleteDialog(index) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
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
                        color: primaryColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: photo is File
                            ? Image.file(
                                photo,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                photo,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                        color: primaryColor,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  log('Error loading image: $error');
                                  return Container(
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
                                          style: GoogleFonts.poppins(
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
                        child: Container(
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
  }

  Widget _buildGenderSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _genders.map((gender) {
        final isSelected = _selectedGender == gender;

        return ChoiceChip(
          label: Text(
            gender,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : textColor,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade300,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildTribeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            value: _selectedTribe,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Select your tribe/ethnicity',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.people, color: primaryColor),
            ),
            items: _tribes.map((tribe) {
              return DropdownMenuItem<String>(
                value: tribe,
                child: Text(
                  tribe,
                  style: GoogleFonts.poppins(color: textColor),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTribe = value;
                _validateForm();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your tribe/ethnicity';
              }
              return null;
            },
            icon: Icon(Icons.arrow_drop_down, color: primaryColor),
            dropdownColor: Colors.white,
            style: GoogleFonts.poppins(fontSize: 16, color: textColor),
          ),
        ),
        if (_selectedTribe == 'Other') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _otherTribeController,
            decoration: InputDecoration(
              labelText: 'Specify your tribe/ethnicity',
              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade700),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(),
            validator: (value) {
              if (_selectedTribe == 'Other' &&
                  (value == null || value.isEmpty)) {
                return 'Please specify your tribe/ethnicity';
              }
              return null;
            },
            onChanged: (_) => _validateForm(),
          ),
        ],
      ],
    );
  }

  Widget _buildAgeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Age Range',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: primaryColor,
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 4,
            ),
            overlayColor: primaryColor.withValues(alpha: 0.2),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 4,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            rangeValueIndicatorShape:
                const PaddleRangeSliderValueIndicatorShape(),
            valueIndicatorColor: primaryColor,
            valueIndicatorTextStyle: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
            ),
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: RangeSlider(
            values: _ageRange,
            min: 18,
            max: 70,
            divisions: 52,
            labels: RangeLabels(
              '${_ageRange.start.round()}',
              '${_ageRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
        ),
      ],
    );
  }
}
