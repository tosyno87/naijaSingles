import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../../models/group_model.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool showJoinButton;
  final bool showAdminBadge;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.showJoinButton = true,
    this.showAdminBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Group Image
                    _buildGroupImage(),
                    const SizedBox(width: 12),
                    
                    // Group Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showAdminBadge) _buildAdminBadge(),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            group.categoryDisplay,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Join Button
                    if (showJoinButton) _buildJoinButton(),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Text(
                  group.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Footer Row
                Row(
                  children: [
                    // Cultural Info
                    if (group.culturalInfo != null) _buildCulturalInfo(),
                    
                    const Spacer(),
                    
                    // Member Count
                    _buildMemberCount(),
                    
                    const SizedBox(width: 8),
                    
                    // Location
                    if (group.location != null) _buildLocation(),
                  ],
                ),
                
                // Tags
                if (group.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTags(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _getCategoryGradient(),
        boxShadow: [
          BoxShadow(
            color: _getCategoryColor().withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: group.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                group.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultIcon();
                },
              ),
            )
          : _buildDefaultIcon(),
    );
  }

  Widget _buildDefaultIcon() {
    return Center(
      child: Custom3DIcons.groups(
        size: 28,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            'Admin',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onJoin,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Join',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCulturalInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.culture.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.culture.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Custom3DIcons.culture(size: 12),
          const SizedBox(width: 4),
          Text(
            group.culturalDisplay,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.culture,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${group.memberCount}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          group.location!,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: group.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.overlayColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  LinearGradient _getCategoryGradient() {
    switch (group.category.toLowerCase()) {
      case 'cultural':
        return LinearGradient(
          colors: [AppColors.culture, AppColors.heritage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'professional':
        return LinearGradient(
          colors: [AppColors.business, AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'social':
        return LinearGradient(
          colors: [AppColors.community, AppColors.info],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'educational':
        return LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'religious':
        return LinearGradient(
          colors: [AppColors.warning, AppColors.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'regional':
        return LinearGradient(
          colors: [AppColors.textPrimary, AppColors.textSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppColors.primaryGradient;
    }
  }

  Color _getCategoryColor() {
    switch (group.category.toLowerCase()) {
      case 'cultural':
        return AppColors.culture;
      case 'professional':
        return AppColors.business;
      case 'social':
        return AppColors.community;
      case 'educational':
        return AppColors.primaryGreen;
      case 'religious':
        return AppColors.warning;
      case 'regional':
        return AppColors.textPrimary;
      default:
        return AppColors.primaryGreen;
    }
  }
}
