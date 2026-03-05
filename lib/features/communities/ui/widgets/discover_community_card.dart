import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../groups/data/services/unified_group_service.dart';

class DiscoverCommunityCard extends StatelessWidget {
  const DiscoverCommunityCard({
    required this.group,
    required this.onTap,
    super.key,
  });

  final UnifiedGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: group.name,
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
            fit: StackFit.expand,
            children: [
              if (group.imageUrl != null && group.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: group.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _buildFallback(),
                  errorWidget: (_, __, ___) => _buildFallback(),
                )
              else
                _buildFallback(),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.70),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 12, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount} members',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      );

  Widget _buildFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen.withValues(alpha: 0.5),
              AppColors.primaryGreen.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.groups_rounded, size: 40, color: Colors.white38),
        ),
      );
}
