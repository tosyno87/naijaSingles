import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../data/services/unified_group_service.dart';

class UnifiedGroupCard extends StatelessWidget {
  const UnifiedGroupCard({
    required this.group,
    required this.onTap,
    this.onJoin,
    this.isMember = false,
    this.isAdmin = false,
    this.featured = false,
    this.hasUnread = false,
    super.key,
  });

  final UnifiedGroup group;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final bool isMember;
  final bool isAdmin;
  final bool featured;
  final bool hasUnread;

  double get _imageHeight => featured ? 180 : 140;

  String get _activityLabel {
    final diff = DateTime.now().difference(group.lastActivityAt);
    if (diff.inMinutes < 30) return 'Active now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '';
  }

  bool get _isActiveNow =>
      DateTime.now().difference(group.lastActivityAt).inMinutes < 30;

  bool get _hasNewMessages => isMember && hasUnread;

  Color get _typeColor => _typeColorFor(group.type);
  IconData get _typeIcon => _typeIconFor(group.type);
  String get _typeLabel => _typeLabelFor(group.type);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${group.name} community',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCoverImage(),
                _buildBody(),
              ],
            ),
          ),
        ),
      );

  Widget _buildCoverImage() => SizedBox(
        height: _imageHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (group.imageUrl != null && group.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: group.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _buildGradientFallback(),
                errorWidget: (_, __, ___) => _buildGradientFallback(),
              )
            else
              _buildGradientFallback(),

            // Bottom gradient for badge readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // Type chip (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _typeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _typeLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Activity badge (top-right)
            if (_isActiveNow)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // New messages badge (bottom-right)
            if (_hasNewMessages)
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_rounded,
                        size: 12,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'New messages',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildBody() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name row + CTA
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          group.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ADMIN',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildCta(),
              ],
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              group.description,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Engagement row
            _buildEngagementRow(),
          ],
        ),
      );

  Widget _buildCta() {
    if (!isMember) {
      return SizedBox(
        height: 32,
        child: ElevatedButton(
          onPressed: onJoin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Join',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final label = group.enableChat ? 'Open Chat' : 'View';
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEngagementRow() => Row(
        children: [
          Icon(Icons.people_outline_rounded,
              size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(
            '${group.memberCount}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          if (group.location != null && group.location!.isNotEmpty) ...[
            _dot(),
            Icon(Icons.location_on_outlined,
                size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                group.location!,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_activityLabel.isNotEmpty) ...[
            _dot(),
            if (_isActiveNow)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 3),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              _activityLabel,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    _isActiveNow ? AppColors.success : Colors.grey.shade500,
              ),
            ),
          ],
        ],
      );

  Widget _dot() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '\u00B7',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade400,
          ),
        ),
      );

  Widget _buildGradientFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _typeColor.withValues(alpha: 0.7),
              _typeColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            _typeIcon,
            size: featured ? 56 : 44,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      );

  // -------------------------------------------------------------------------
  // Type mapping helpers (static, no instance state needed)
  // -------------------------------------------------------------------------

  static String _typeLabelFor(GroupType type) {
    switch (type) {
      case GroupType.music:
        return 'Music';
      case GroupType.sports:
        return 'Sports';
      case GroupType.travel:
        return 'Travel';
      case GroupType.food:
        return 'Food';
      case GroupType.art:
        return 'Art';
      case GroupType.career:
        return 'Career';
      case GroupType.fitness:
        return 'Fitness';
      case GroupType.gaming:
        return 'Gaming';
      case GroupType.reading:
        return 'Reading';
      case GroupType.movies:
        return 'Movies';
      case GroupType.events:
        return 'Events';
      case GroupType.networking:
        return 'Networking';
      case GroupType.support:
        return 'Support';
      case GroupType.study:
        return 'Study';
      case GroupType.local:
        return 'Local';
      case GroupType.tech:
        return 'Technology';
      case GroupType.fashion:
        return 'Fashion';
      case GroupType.pets:
        return 'Pets';
      case GroupType.parenting:
        return 'Parenting';
      case GroupType.seniors:
        return 'Seniors';
    }
  }

  static Color _typeColorFor(GroupType type) {
    switch (type) {
      case GroupType.music:
        return Colors.purple;
      case GroupType.sports:
        return Colors.orange;
      case GroupType.travel:
        return Colors.blue;
      case GroupType.food:
        return Colors.red;
      case GroupType.art:
        return Colors.pink;
      case GroupType.career:
        return Colors.indigo;
      case GroupType.fitness:
        return Colors.green;
      case GroupType.gaming:
        return Colors.deepPurple;
      case GroupType.reading:
        return Colors.brown;
      case GroupType.movies:
        return Colors.teal;
      case GroupType.events:
        return Colors.amber;
      case GroupType.networking:
        return Colors.cyan;
      case GroupType.support:
        return Colors.lightBlue;
      case GroupType.study:
        return Colors.deepOrange;
      case GroupType.local:
        return Colors.lightGreen;
      case GroupType.tech:
        return Colors.blueGrey;
      case GroupType.fashion:
        return Colors.pinkAccent;
      case GroupType.pets:
        return Colors.amberAccent;
      case GroupType.parenting:
        return Colors.lightGreenAccent;
      case GroupType.seniors:
        return Colors.grey;
    }
  }

  static IconData _typeIconFor(GroupType type) {
    switch (type) {
      case GroupType.music:
        return Icons.music_note;
      case GroupType.sports:
        return Icons.sports_soccer;
      case GroupType.travel:
        return Icons.travel_explore;
      case GroupType.food:
        return Icons.restaurant;
      case GroupType.art:
        return Icons.palette;
      case GroupType.career:
        return Icons.work;
      case GroupType.fitness:
        return Icons.fitness_center;
      case GroupType.gaming:
        return Icons.sports_esports;
      case GroupType.reading:
        return Icons.menu_book;
      case GroupType.movies:
        return Icons.movie;
      case GroupType.events:
        return Icons.event;
      case GroupType.networking:
        return Icons.people;
      case GroupType.support:
        return Icons.support_agent;
      case GroupType.study:
        return Icons.school;
      case GroupType.local:
        return Icons.location_on;
      case GroupType.tech:
        return Icons.computer;
      case GroupType.fashion:
        return Icons.checkroom;
      case GroupType.pets:
        return Icons.pets;
      case GroupType.parenting:
        return Icons.child_care;
      case GroupType.seniors:
        return Icons.elderly;
    }
  }
}
