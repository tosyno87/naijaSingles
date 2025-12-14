import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  final _emailController = TextEditingController();

  // Afropeep MVP Color Scheme
  static const Color backgroundColor = Colors.white; // Clean white
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static const Color errorColor = Color(0xFFFF5A5F); // Red for errors
  static const Color successColor = Color(0xFF4CAF50); // Green for success
  static const Color warningColor = Color(0xFFFF9500); // Orange for warnings
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

  String _selectedCategory = 'General Feedback';
  int _rating = 0;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General Feedback',
    'Bug Report',
    'Feature Request',
    'User Experience',
    'Performance Issue',
    'Safety Concern',
    'Account Issue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  void _loadUserEmail() {
    final user = _auth.currentUser;
    if (user?.email != null) {
      _emailController.text = user!.email!;
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Feedback',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // Rating Section
              _buildRatingSection(),
              const SizedBox(height: 24),

              // Category Selection
              _buildCategorySection(),
              const SizedBox(height: 24),

              // Email Field
              _buildEmailField(),
              const SizedBox(height: 24),

              // Feedback Text Area
              _buildFeedbackField(),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 16),

              // Tips Section
              _buildTipsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feedback,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We Value Your Feedback',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve Afropeep by sharing your thoughts, reporting bugs, or suggesting new features.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate Your Experience',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How would you rate your overall experience with Afropeep?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star,
                    size: 40,
                    color:
                        index < _rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              );
            }),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getRatingColor(_rating),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback Category',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'What type of feedback are you providing?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Email',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll use this email to follow up on your feedback if needed.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: GoogleFonts.montserrat(color: textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(Icons.email, color: primaryColor),
            ),
            style: GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackField() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Feedback',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please provide detailed feedback. The more specific you are, the better we can help.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _feedbackController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: GoogleFonts.montserrat(color: textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.montserrat(fontSize: 16, color: textPrimary),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your feedback';
              }
              if (value.trim().length < 10) {
                return 'Please provide more detailed feedback (at least 10 characters)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Submitting...',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Submit Feedback',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tips for Better Feedback',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Be specific about the issue or suggestion'),
          _buildTip('Include steps to reproduce bugs'),
          _buildTip('Mention your device and app version for technical issues'),
          _buildTip('Suggest solutions if you have ideas'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return errorColor;
    if (rating == 3) return warningColor;
    return successColor;
  }

  String _getHintText() {
    switch (_selectedCategory) {
      case 'Bug Report':
        return 'Describe the bug you encountered. Include what you were doing when it happened, what you expected to happen, and what actually happened.';
      case 'Feature Request':
        return 'Describe the feature you\'d like to see added. Explain how it would improve your experience and why it would be useful.';
      case 'Performance Issue':
        return 'Describe the performance issue. Is the app slow, crashing, or not responding? When does this happen?';
      case 'Safety Concern':
        return 'Describe your safety concern. We take all safety reports seriously and will investigate promptly.';
      case 'Account Issue':
        return 'Describe the issue with your account. Are you having trouble logging in, updating your profile, or accessing features?';
      default:
        return 'Share your thoughts, suggestions, or any issues you\'ve experienced. We appreciate all feedback!';
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = _auth.currentUser;
      final feedbackData = {
        'userId': user?.uid,
        'email': _emailController.text.trim(),
        'category': _selectedCategory,
        'rating': _rating,
        'feedback': _feedbackController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
        'deviceInfo': {
          'platform': Theme.of(context).platform.toString(),
        },
      };

      await _firestore.collection('feedback').add(feedbackData);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            contentPadding: const EdgeInsets.all(24),
            title: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.check_circle, color: successColor, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank You!',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your feedback has been submitted successfully. We appreciate you taking the time to help us improve Afropeep.',
                  style: GoogleFonts.montserrat(
                    color: textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'We\'ll review your feedback and may follow up via email if needed.',
                          style: GoogleFonts.montserrat(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          ),
        );
      }
    } catch (e) {
      log('Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit feedback. Please try again.',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
