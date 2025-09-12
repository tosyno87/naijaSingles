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
                _buildMutualInterests(),
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
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLastSeenText(),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Nationality Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getNationalityText(),
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
        gradient: LinearGradient(
          colors: [
            AppColors.culture.withOpacity(0.1),
            AppColors.heritage.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.culture.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.culture.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Custom3DIcons.culture(size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nationality & Tribe',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.culture,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getNationalityText(),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_getTribeText().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getTribeText(),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Cultural verification badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildMutualInterests() {
    final mutualInterests = _getMutualInterests();
    if (mutualInterests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.primaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Cultural Connection',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: mutualInterests.map((interest) => _buildMutualInterestTag(interest)).toList(),
          ),
        ],
      ),
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

  Widget _buildMutualInterestTag(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            interest,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    if (user.bio?.isEmpty == true) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.overlayColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'About',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            user.bio ?? '',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
            color: AppColors.info,
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
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Custom3DIcons.block(size: 20),
            label: 'Block',
            onPressed: onBlock,
            color: AppColors.error,
            isDestructive: true,
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
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary 
              ? color 
              : isDestructive 
                  ? Colors.transparent
                  : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive 
                ? color.withOpacity(0.4)
                : color.withOpacity(0.3),
            width: isDestructive ? 1 : 1.5,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: isPrimary 
                    ? Colors.white 
                    : isDestructive 
                        ? color.withOpacity(0.8)
                        : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNationalityText() {
    // Extract nationality from user data - using available fields
    if (user.living_in?.isNotEmpty == true) {
      // If living_in contains country info, use it
      final location = user.living_in!.toLowerCase();
      if (location.contains('nigeria') || location.contains('lagos') || location.contains('abuja')) {
        return 'Nigerian';
      } else if (location.contains('ghana') || location.contains('accra')) {
        return 'Ghanaian';
      } else if (location.contains('kenya') || location.contains('nairobi')) {
        return 'Kenyan';
      } else if (location.contains('south africa') || location.contains('johannesburg') || location.contains('cape town')) {
        return 'South African';
      } else if (location.contains('uk') || location.contains('london') || location.contains('manchester')) {
        return 'British-Nigerian';
      } else if (location.contains('usa') || location.contains('america') || location.contains('new york') || location.contains('atlanta')) {
        return 'American-Nigerian';
      } else if (location.contains('canada') || location.contains('toronto') || location.contains('vancouver')) {
        return 'Canadian-Nigerian';
      }
    }
    return 'Nigerian'; // Default to Nigerian for demo
  }

  String _getTribeText() {
    // Extract tribe from user data - using available fields
    if (user.profession?.isNotEmpty == true) {
      final profession = user.profession!.toLowerCase();
      // Check if profession field contains tribe info
      if (profession.contains('yoruba') || profession.contains('igbo') || profession.contains('hausa')) {
        return profession;
      }
    }
    
    // Simulate tribe based on name patterns (for demo purposes)
    final name = user.name?.toLowerCase() ?? '';
    if (name.contains('ade') || name.contains('tunde') || name.contains('kemi') || name.contains('yemi')) {
      return 'Yoruba';
    } else if (name.contains('chi') || name.contains('nkechi') || name.contains('chukwu') || name.contains('nnamdi')) {
      return 'Igbo';
    } else if (name.contains('ahmed') || name.contains('fatima') || name.contains('hassan') || name.contains('aisha')) {
      return 'Hausa';
    }
    
    return 'Yoruba'; // Default tribe for demo
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

  List<String> _getMutualInterests() {
    // Simulate cultural connections - in real app, this would compare with current user
    List<String> connections = [];
    
    // Add nationality connection
    final nationality = _getNationalityText();
    if (nationality.contains('Nigerian')) {
      connections.add('🇳🇬 Nigerian');
    } else if (nationality.contains('Ghanaian')) {
      connections.add('🇬🇭 Ghanaian');
    } else if (nationality.contains('Kenyan')) {
      connections.add('🇰🇪 Kenyan');
    }
    
    // Add tribe connection
    final tribe = _getTribeText();
    if (tribe.isNotEmpty) {
      connections.add('🏛️ $tribe');
    }
    
    // Add some common interests
    final interests = _getInterests();
    if (interests.isNotEmpty) {
      connections.add('🎵 ${interests.first}');
    }
    
    return connections.take(2).toList();
  }

  String _getLastSeenText() {
    if (user.lastSeen == null) return 'Recently active';
    
    final now = DateTime.now();
    final lastSeen = user.lastSeen!;
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 60) {
      return 'Active now';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else {
      return 'Active ${difference.inDays}d ago';
    }
  }
}
