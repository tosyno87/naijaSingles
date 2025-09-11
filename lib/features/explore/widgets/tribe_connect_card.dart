import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/widgets/custom_3d_icons.dart';
import '../../../models/user_model.dart';

class TribeConnectCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onConnect;
  final VoidCallback onMessage;
  final VoidCallback onSave;
  final VoidCallback onBlock;

  const TribeConnectCard({
    super.key,
    required this.user,
    required this.onConnect,
    required this.onMessage,
    required this.onSave,
    required this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image Section
          _buildProfileImage(),
          
          // Profile Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(),
                const SizedBox(height: 12),
                _buildCulturalInfo(),
                const SizedBox(height: 12),
                _buildLocationAndLanguages(),
                const SizedBox(height: 12),
                _buildInterests(),
                const SizedBox(height: 12),
                _buildBio(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        image: user.imageUrl?.isNotEmpty == true
            ? DecorationImage(
                image: NetworkImage(user.imageUrl![0]),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.imageUrl?.isEmpty == true
          ? Container(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: Custom3DIcons.profile(
                  size: 60,
                  color: AppColors.primaryGreen,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBasicInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name ?? 'Unknown',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (user.age != null)
                Text(
                  '${user.age} years old',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        // Cultural Heritage Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getHeritageText(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCulturalInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.culture.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.culture.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Custom3DIcons.culture(size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Heritage: ${_getHeritageText()}',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndLanguages() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoChip(
            icon: Custom3DIcons.location(size: 16),
            text: user.living_in ?? 'Location not set',
            color: AppColors.business,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoChip(
            icon: Custom3DIcons.translate(size: 16),
            text: _getLanguagesText(),
            color: AppColors.community,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required Widget icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    final interests = _getInterests();
    if (interests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: interests.map((interest) => _buildInterestTag(interest)).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestTag(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        interest,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildBio() {
    if (user.bio?.isEmpty == true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          user.bio ?? '',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Custom3DIcons.message(size: 20),
            label: 'Message',
            onPressed: onMessage,
            color: AppColors.community,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Custom3DIcons.connect(size: 20),
            label: 'Connect',
            onPressed: onConnect,
            color: AppColors.primaryGreen,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Custom3DIcons.save(size: 20),
            label: 'Save',
            onPressed: onSave,
            color: AppColors.business,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Custom3DIcons.block(size: 20),
            label: 'Block',
            onPressed: onBlock,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeritageText() {
    // Extract heritage from user data - using available fields
    if (user.education?.isNotEmpty == true) {
      return user.education!;
    }
    return 'African Heritage';
  }

  String _getLanguagesText() {
    // Using profession as a proxy for skills/interests
    if (user.profession?.isNotEmpty == true) {
      return user.profession!;
    }
    return 'English';
  }

  List<String> _getInterests() {
    // Using available fields to create interest tags
    List<String> interests = [];
    if (user.profession?.isNotEmpty == true) {
      interests.add(user.profession!);
    }
    if (user.education?.isNotEmpty == true) {
      interests.add(user.education!);
    }
    if (user.lookingFor?.isNotEmpty == true) {
      interests.add(user.lookingFor!);
    }
    
    if (interests.isEmpty) {
      return ['Culture', 'Music', 'Community'];
    }
    return interests.take(3).toList();
  }
}
