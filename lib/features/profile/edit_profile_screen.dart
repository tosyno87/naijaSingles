import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../user/controllers/onboarding_controller.dart';

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
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // Selected values
  String? _selectedTribe;
  String? _selectedIntent;
  List<String> _selectedInterests = [];
  File? _profileImage;
  String? _profileImageUrl;
  
  // Lists for dropdowns and selections
  final List<String> _tribes = [
    'Yoruba', 'Igbo', 'Hausa', 'Fulani', 'Edo', 'Ijaw', 'Kanuri', 'Ibibio', 
    'Tiv', 'Efik', 'Nupe', 'Urhobo', 'Igala', 'Other'
  ];
  
  final List<String> _intents = [
    'Dating', 'Friendship', 'Networking'
  ];
  
  final List<String> _interests = [
    'Music', 'Movies', 'Travel', 'Food', 'Art', 'Sports', 'Reading', 'Fashion',
    'Photography', 'Dancing', 'Cooking', 'Fitness', 'Technology', 'Nature',
    'Politics', 'Gaming', 'Writing', 'Volunteering'
  ];
  
  // Image picker
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    
    // Load existing user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  void _loadUserData() {
    final controller = Provider.of<OnboardingController>(context, listen: false);
    
    // Load name
    if (controller.userName != null) {
      _nameController.text = controller.userName!;
    }
    
    // Calculate age from date of birth
    if (controller.dateOfBirth != null) {
      final now = DateTime.now();
      final age = now.year - controller.dateOfBirth!.year - 
          (now.month < controller.dateOfBirth!.month || 
          (now.month == controller.dateOfBirth!.month && now.day < controller.dateOfBirth!.day) ? 1 : 0);
      
      _ageController.text = age.toString();
    }
    
    // Load location
    if (controller.locationName != null) {
      _locationController.text = controller.locationName!;
    }
    
    // Load bio
    if (controller.bio != null) {
      _bioController.text = controller.bio!;
    }
    
    // Load tribe
    if (controller.tribe != null) {
      setState(() {
        _selectedTribe = controller.tribe;
      });
    }
    
    // Load intent
    if (controller.intent != null) {
      setState(() {
        _selectedIntent = controller.intent;
      });
    }
    
    // Load interests (using genres as interests for now)
    if (controller.genres.isNotEmpty) {
      setState(() {
        _selectedInterests = List.from(controller.genres);
      });
    }
    
    // Load profile image URL (if any)
    if (controller.photos.isNotEmpty) {
      setState(() {
        _profileImageUrl = controller.photos.first;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
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
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // Build image source option
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF008037).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF008037),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  // Save profile data
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
      // Update name
      controller.updateUserName(_nameController.text.trim());
      
      // Update age (convert to date of birth)
      final age = int.tryParse(_ageController.text.trim());
      if (age != null) {
        final now = DateTime.now();
        final dob = DateTime(now.year - age, now.month, now.day);
        controller.updateDateOfBirth(dob);
      }
      
      // Update location
      // In a real app, we would also update lat/lng from a location picker
      controller.updateLocation(0.0, 0.0, _locationController.text.trim());
      
      // Update bio
      controller.updateBio(_bioController.text.trim());
      
      // Update tribe
      if (_selectedTribe != null) {
        controller.updateTribe(_selectedTribe!);
      }
      
      // Update intent
      if (_selectedIntent != null) {
        controller.updateIntent(_selectedIntent!);
      }
      
      // Update interests (using genres for now)
      controller.updateGenres(_selectedInterests);
      
      // Update profile image
      // In a real app, we would upload the image to storage and get a URL
      // For now, we'll just use a placeholder
      if (_profileImage != null) {
        // This is a placeholder. In a real app, we would upload the image
        // and get a URL back
        controller.updatePhotos(['profile_image_url']);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF008037),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Background color for the app
    const Color backgroundColor = Color(0xFFFDF6EC);
    
    // Deep green color for accents
    const Color deepGreen = Color(0xFF008037);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: deepGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.brown.shade800,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: deepGreen,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    // Profile Image
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: deepGreen,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              )
                            : _profileImageUrl != null
                                ? Image.network(
                                    _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                  ),
                      ),
                    ),
                    
                    // Edit Icon
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: deepGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Basic Info Section
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Age Field
                    _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      icon: Icons.cake,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your age';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18 || age > 100) {
                          return 'Please enter a valid age (18-100)';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location Field
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'City, Country',
                      icon: Icons.location_on,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bio Section
              _buildSectionTitle('About Me'),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _bioController,
                      maxLines: 5,
                      minLines: 3,
                      maxLength: 300,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write a short bio about yourself...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: deepGreen, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write a short bio';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Cultural Identity Section
              _buildSectionTitle('Cultural Identity'),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tribe Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTribe,
                      decoration: InputDecoration(
                        labelText: 'Tribe / Ethnic Group',
                        labelStyle: GoogleFonts.poppins(
                          color: deepGreen,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.people,
                          color: deepGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: deepGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      items: _tribes.map((String tribe) {
                        return DropdownMenuItem<String>(
                          value: tribe,
                          child: Text(tribe),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTribe = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your tribe/ethnic group';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Intent Section
              _buildSectionTitle('What are you looking for?'),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intent Selection
                    DropdownButtonFormField<String>(
                      value: _selectedIntent,
                      decoration: InputDecoration(
                        labelText: 'I\'m here for',
                        labelStyle: GoogleFonts.poppins(
                          color: deepGreen,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.favorite,
                          color: deepGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: deepGreen, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      items: _intents.map((String intent) {
                        return DropdownMenuItem<String>(
                          value: intent,
                          child: Text(intent),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedIntent = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select what you\'re looking for';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Interests Section
              _buildSectionTitle('Interests'),
              const SizedBox(height: 8),
              Text(
                'Select your interests (up to 5)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(
                        interest,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected ? deepGreen : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedInterests.length < 5) {
                              _selectedInterests.add(interest);
                            } else {
                              // Show message that max 5 interests are allowed
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'You can select up to 5 interests',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.orange,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: deepGreen.withOpacity(0.1),
                      checkmarkColor: deepGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? deepGreen : Colors.grey[400]!,
                          width: isSelected ? 1 : 0.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Save Button
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: deepGreen,
                      foregroundColor: Colors.white,
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
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.brown.shade800,
      ),
    );
  }
  
  // Build info card
  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
  
  // Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(
        fontSize: 15,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF008037),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF008037),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
