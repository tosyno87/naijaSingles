import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';

/// Mode-specific profile sections that show different information based on relationship intent
class ModeSpecificProfileSections extends StatelessWidget {
  const ModeSpecificProfileSections({
    required this.user,
    required this.selectedMode,
    super.key,
  });
  final UserModel user;
  final String selectedMode;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Mode-specific header
          _buildModeHeader(),

          const SizedBox(height: 16),

          // Mode-specific content sections
          ..._buildModeSpecificSections(),
        ],
      );

  Widget _buildModeHeader() {
    final config = _getModeConfig();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            config.icon,
            color: config.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: config.color,
                  ),
                ),
                Text(
                  config.subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: config.color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModeSpecificSections() {
    switch (selectedMode) {
      case 'Dating':
        return _buildDatingSections();
      case 'Friendship':
        return _buildFriendshipSections();
      case 'Networking':
        return _buildNetworkingSections();
      default:
        return _buildDatingSections();
    }
  }

  List<Widget> _buildDatingSections() => [
        _buildSection(
          title: 'Relationship Goals',
          icon: Icons.favorite,
          color: Colors.pink,
          children: [
            _buildInfoRow('Looking for', _getLookingFor()),
            _buildInfoRow('Relationship Status', _getRelationshipStatus()),
            _buildInfoRow('Lifestyle', _getLifestyle()),
          ],
        ),
        if (_getDealbreakers().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Important to Me',
            icon: Icons.priority_high,
            color: Colors.red,
            children: [
              _buildTagsList(_getDealbreakersList()),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildSection(
          title: 'Personality',
          icon: Icons.psychology,
          color: Colors.purple,
          children: [
            _buildInfoRow('Communication Style', _getCommunicationStyle()),
            _buildInfoRow('Social Energy', _getSocialEnergy()),
            _buildInfoRow('Love Language', _getLoveLanguage()),
          ],
        ),
      ];

  List<Widget> _buildFriendshipSections() => [
        _buildSection(
          title: 'Social Interests',
          icon: Icons.people,
          color: Colors.green,
          children: [
            _buildInfoRow('Group Activities', _getGroupActivities()),
            _buildInfoRow('Social Style', _getSocialStyle()),
            _buildInfoRow('Availability', _getAvailability()),
          ],
        ),
        if (_getHobbies().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Hobbies & Interests',
            icon: Icons.sports,
            color: Colors.blue,
            children: [
              _buildTagsList(_getHobbiesList()),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildSection(
          title: 'Friendship Goals',
          icon: Icons.group,
          color: Colors.teal,
          children: [
            _buildInfoRow('Friend Group Size', _getFriendGroupSize()),
            _buildInfoRow('Activity Level', _getActivityLevel()),
            _buildInfoRow('Meeting Style', _getMeetingStyle()),
          ],
        ),
      ];

  List<Widget> _buildNetworkingSections() => [
        _buildSection(
          title: 'Professional Info',
          icon: Icons.business_center,
          color: Colors.orange,
          children: [
            _buildInfoRow('Industry', _getIndustry()),
            _buildInfoRow('Career Level', _getCareerLevel()),
            _buildInfoRow('Company', _getCompany()),
          ],
        ),
        if (_getSkills().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Skills & Expertise',
            icon: Icons.lightbulb,
            color: Colors.amber,
            children: [
              _buildTagsList(_getSkillsList()),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildSection(
          title: 'Networking Goals',
          icon: Icons.handshake,
          color: Colors.indigo,
          children: [
            _buildInfoRow('Professional Focus', _getProfessionalFocus()),
            _buildInfoRow('Collaboration Style', _getCollaborationStyle()),
            _buildInfoRow(
              'Networking Availability',
              _getNetworkingAvailability(),
            ),
          ],
        ),
      ];

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsList(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map(_buildTag).toList(),
    );
  }

  Widget _buildTag(String tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF008037).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF008037).withValues(alpha: 0.3)),
        ),
        child: Text(
          tag,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF008037),
          ),
        ),
      );

  // Mode configuration
  _ModeConfig _getModeConfig() {
    switch (selectedMode) {
      case 'Dating':
        return _ModeConfig(
          icon: Icons.favorite,
          color: Colors.pink,
          title: 'Dating Profile',
          subtitle: 'Looking for romantic connections',
        );
      case 'Friendship':
        return _ModeConfig(
          icon: Icons.people,
          color: Colors.green,
          title: 'Friendship Profile',
          subtitle: 'Making new friends and social connections',
        );
      case 'Networking':
        return _ModeConfig(
          icon: Icons.business_center,
          color: Colors.orange,
          title: 'Professional Profile',
          subtitle: 'Career connections and business opportunities',
        );
      default:
        return _ModeConfig(
          icon: Icons.favorite,
          color: Colors.pink,
          title: 'Dating Profile',
          subtitle: 'Looking for romantic connections',
        );
    }
  }

  // Data getters - these would be populated from user profile data
  String _getLookingFor() => user.lookingFor ?? 'Not specified';
  String _getRelationshipStatus() => 'Single'; // This would come from user data
  String _getLifestyle() => 'Active'; // This would come from user data
  String _getDealbreakers() => ''; // This would come from user data
  String _getCommunicationStyle() => 'Direct'; // This would come from user data
  String _getSocialEnergy() => 'Balanced'; // This would come from user data
  String _getLoveLanguage() => 'Quality Time'; // This would come from user data

  String _getGroupActivities() =>
      'Sports, Movies, Dining'; // This would come from user data
  String _getSocialStyle() => 'Outgoing'; // This would come from user data
  String _getAvailability() => 'Weekends'; // This would come from user data
  String _getHobbies() => ''; // This would come from user data
  String _getFriendGroupSize() =>
      'Small groups (3-5)'; // This would come from user data
  String _getActivityLevel() => 'Moderate'; // This would come from user data
  String _getMeetingStyle() =>
      'Casual gatherings'; // This would come from user data

  String _getIndustry() => user.job_title ?? 'Not specified';
  String _getCareerLevel() => 'Mid-level'; // This would come from user data
  String _getCompany() => user.company ?? 'Not specified';
  String _getSkills() => ''; // This would come from user data
  String _getProfessionalFocus() =>
      'Technology'; // This would come from user data
  String _getCollaborationStyle() =>
      'Team player'; // This would come from user data
  String _getNetworkingAvailability() =>
      'Business hours'; // This would come from user data

  List<String> _getDealbreakersList() {
    // This would return actual dealbreakers from user data
    return [];
  }

  List<String> _getHobbiesList() {
    // This would return actual hobbies from user data
    return [];
  }

  List<String> _getSkillsList() {
    // This would return actual skills from user data
    return [];
  }
}

class _ModeConfig {
  _ModeConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}
