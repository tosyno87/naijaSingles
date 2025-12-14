import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/content_moderation_service.dart';
import '../../../services/profile_verification_service.dart';

/// Example of how to integrate Content Moderation and Profile Verification
/// into your existing profile screens
class ProfileWithModerationExample extends StatefulWidget {
  final String userId;

  const ProfileWithModerationExample({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileWithModerationExample> createState() =>
      _ProfileWithModerationExampleState();
}

class _ProfileWithModerationExampleState
    extends State<ProfileWithModerationExample> {
  final _contentModerationService = ContentModerationService();
  final _profileVerificationService = ProfileVerificationService();

  VerificationStatus? _verificationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final status = await _profileVerificationService
          .getUserVerificationStatus(widget.userId);
      setState(() {
        _verificationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile with Moderation'),
        actions: [
          // Report button
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _showReportDialog,
            tooltip: 'Report Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header with Verification Badge
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // Profile Content
            _buildProfileContent(),

            const SizedBox(height: 24),

            // Verification Section
            _buildVerificationSection(),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 40),
            ),

            const SizedBox(width: 16),

            // Profile Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'John Doe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Verification Badge
                      if (_verificationStatus != null)
                        _buildVerificationBadge(_verificationStatus!),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '25 years old',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const Text(
                    'Lagos, Nigeria',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    final badge = _profileVerificationService.getVerificationBadge(status);
    final text = _profileVerificationService.getVerificationStatusText(status);

    Color badgeColor;
    switch (status) {
      case VerificationStatus.verified:
        badgeColor = Colors.green;
        break;
      case VerificationStatus.pending:
        badgeColor = Colors.orange;
        break;
      case VerificationStatus.rejected:
        badgeColor = Colors.red;
        break;
      case VerificationStatus.unverified:
        badgeColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge, style: TextStyle(color: badgeColor)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Me',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I love traveling, cooking, and meeting new people. Looking for someone to share adventures with!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Verification Types
            ...VerificationType.values.map((type) {
              return _buildVerificationTypeRow(type);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTypeRow(VerificationType type) {
    final requirements =
        _profileVerificationService.getVerificationRequirements(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            _getVerificationIcon(type),
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirements['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  requirements['description'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _requestVerification(type),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  IconData _getVerificationIcon(VerificationType type) {
    switch (type) {
      case VerificationType.email:
        return Icons.email;
      case VerificationType.phone:
        return Icons.phone;
      case VerificationType.photo:
        return Icons.photo_camera;
      case VerificationType.identity:
        return Icons.badge;
      case VerificationType.employment:
        return Icons.work;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showReportDialog,
            icon: const Icon(Icons.flag),
            label: const Text('Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showVerificationDialog,
            icon: const Icon(Icons.verified_user),
            label: const Text('Verify'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Profile'),
        content: const Text('Why are you reporting this profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _reportProfile();
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Verification'),
        content:
            const Text('Which type of verification would you like to request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestVerification(VerificationType.photo);
            },
            child: const Text('Photo Verification'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProfile() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final success = await _contentModerationService.reportContent(
        contentType: 'profile',
        contentId: widget.userId,
        reporterId: currentUserId,
        reason: 'Inappropriate content',
        details: 'Reported from profile screen',
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _requestVerification(VerificationType type) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final canRequest =
          await _profileVerificationService.canRequestVerification(
        currentUserId,
        type,
      );

      if (!canRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot request this verification type')),
        );
        return;
      }

      final success = await _profileVerificationService.requestVerification(
        userId: currentUserId,
        type: type,
        verificationData: _getVerificationData(type),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification requested successfully')),
        );
        _loadVerificationStatus(); // Refresh status
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request verification')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Map<String, dynamic> _getVerificationData(VerificationType type) {
    switch (type) {
      case VerificationType.email:
        return {'email': 'user@example.com', 'verificationCode': '123456'};
      case VerificationType.phone:
        return {'phoneNumber': '+2341234567890', 'verificationCode': '123456'};
      case VerificationType.photo:
        return {
          'photos': ['photo1.jpg', 'photo2.jpg'],
          'selfie': 'selfie.jpg'
        };
      case VerificationType.identity:
        return {
          'idType': 'passport',
          'idNumber': 'A1234567',
          'idPhoto': 'id.jpg'
        };
      case VerificationType.employment:
        return {
          'company': 'Tech Company',
          'position': 'Developer',
          'email': 'work@company.com'
        };
    }
  }
}
