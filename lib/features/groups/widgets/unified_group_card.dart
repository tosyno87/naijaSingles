import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/constants/app_colors.dart';
import '../data/services/unified_group_service.dart';

enum GroupBadge { trending, isNew }

class UnifiedGroupCard extends StatelessWidget {
  const UnifiedGroupCard({
    required this.group,
    required this.onTap,
    this.onJoin,
    this.isMember = false,
    this.isAdmin = false,
    this.featured = false,
    this.hasUnread = false,
    this.badge,
    this.memberAvatars = const [],
    super.key,
  });

  final UnifiedGroup group;
  final VoidCallback onTap;
  final VoidCallback? onJoin;
  final bool isMember;
  final bool isAdmin;
  final bool featured;
  final bool hasUnread;
  final GroupBadge? badge;
  final List<String?> memberAvatars;

  double get _imageHeight => featured ? 200 : 170;

  bool get _isActiveNow =>
      DateTime.now().difference(group.lastActivityAt).inMinutes < 30;

  bool get _hasNewMessages => isMember && hasUnread;

  bool get _activeThisWeek =>
      DateTime.now().difference(group.lastActivityAt).inDays < 7;

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

  // ---------------------------------------------------------------------------
  // Cover image with overlays
  // ---------------------------------------------------------------------------

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
                placeholder: (_, __) => _buildBannerFallback(),
                errorWidget: (_, __, ___) => _buildBannerFallback(),
              )
            else
              _buildBannerFallback(),

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

            // Ranking badge (top-right)
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge == GroupBadge.isNew
                        ? const Color(0xFF5C6BC0)
                        : const Color(0xFFFF6D00),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badge == GroupBadge.isNew
                            ? Icons.fiber_new_rounded
                            : Icons.trending_up_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        badge == GroupBadge.isNew ? 'New' : 'Trending',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active now badge
            if (_isActiveNow)
              Positioned(
                top: badge != null ? 40 : 12,
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
                      const Icon(
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

  // ---------------------------------------------------------------------------
  // Card body — name, description, metadata row, CTA
  // ---------------------------------------------------------------------------

  Widget _buildBody() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + admin badge
            Row(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

            const SizedBox(height: 4),

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

            // Location line (subtle, below description)
            if (group.location != null && group.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      group.location!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Metadata row: avatar stack + activity
            _buildMetadataRow(),

            const SizedBox(height: 12),

            // Full-width CTA
            _buildFullWidthCta(),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Metadata row — avatar stack + activity signal
  // ---------------------------------------------------------------------------

  Widget _buildMetadataRow() => Row(
        children: [
          _buildAvatarStack(),
          if (_activeThisWeek) ...[
            const SizedBox(width: 12),
            const Icon(
              Icons.bolt_rounded,
              size: 14,
              color: AppColors.primaryGreen,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                'Active this week',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryGreen,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );

  // ---------------------------------------------------------------------------
  // Avatar stack — overlapping circles + member count
  // ---------------------------------------------------------------------------

  Widget _buildAvatarStack() {
    final shown = memberAvatars.length.clamp(0, 3);
    final remaining = group.memberCount - shown;
    const diameter = 24.0;
    const overlap = 8.0;
    final stackWidth =
        shown > 0 ? diameter + (shown - 1) * (diameter - overlap) : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown > 0)
          SizedBox(
            width: stackWidth,
            height: diameter,
            child: Stack(
              children: List.generate(shown, (i) {
                final url = memberAvatars[i];
                return Positioned(
                  left: i * (diameter - overlap),
                  child: Container(
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: (diameter - 4) / 2,
                      backgroundColor: _typeColor.withValues(alpha: 0.3),
                      backgroundImage: url != null ? NetworkImage(url) : null,
                      child: url == null
                          ? Icon(
                              Icons.person,
                              size: 12,
                              color: _typeColor,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          )
        else
          Icon(
            Icons.people_outline_rounded,
            size: 16,
            color: Colors.grey.shade500,
          ),
        const SizedBox(width: 6),
        Text(
          remaining > 0 && shown > 0
              ? '+$remaining ${remaining == 1 ? 'member' : 'members'}'
              : _memberLabel,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String get _memberLabel {
    if (group.memberCount >= 1000) {
      return '${(group.memberCount / 1000).toStringAsFixed(1)}k members';
    }
    return '${group.memberCount} ${group.memberCount == 1 ? 'member' : 'members'}';
  }

  // ---------------------------------------------------------------------------
  // Full-width CTA button
  // ---------------------------------------------------------------------------

  Widget _buildFullWidthCta() {
    if (!isMember) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: onJoin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Join Community',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final label = group.enableChat ? 'Open Chat' : 'View Community';
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          side: const BorderSide(color: AppColors.primaryGreen),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Banner fallback — type-specific asset > gradient
  // ---------------------------------------------------------------------------

  Widget _buildBannerFallback() {
    final assetPath = _typeAssetFor(group.type);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => _buildGradientFallback(),
      );
    }
    return _buildGradientFallback();
  }

  Widget _buildGradientFallback() {
    final base = HSLColor.fromColor(_typeColor);
    final lighter = base.withLightness(
      (base.lightness + 0.15).clamp(0.0, 1.0),
    );
    final darker = base.withLightness(
      (base.lightness - 0.1).clamp(0.0, 1.0),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [
                lighter.toColor(),
                _typeColor.withValues(alpha: 0.85),
                darker.toColor().withValues(alpha: 0.9),
              ],
            ),
          ),
        ),
        Positioned(
          right: -20,
          bottom: -20,
          child: Icon(
            _typeIcon,
            size: featured ? 100 : 80,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Center(
          child: Icon(
            _typeIcon,
            size: featured ? 48 : 38,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Type-specific asset mapping (top 5 types get lifestyle banners)
  // ---------------------------------------------------------------------------

  static String? _typeAssetFor(GroupType type) {
    switch (type) {
      case GroupType.gaming:
        return 'assets/images/placeholders/community_gaming.png';
      case GroupType.career:
      case GroupType.networking:
        return 'assets/images/placeholders/community_career.png';
      case GroupType.travel:
        return 'assets/images/placeholders/community_travel.png';
      case GroupType.music:
        return 'assets/images/placeholders/community_music.png';
      case GroupType.sports:
      case GroupType.fitness:
        return 'assets/images/placeholders/community_sports.png';
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Type mapping helpers
  // ---------------------------------------------------------------------------

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
