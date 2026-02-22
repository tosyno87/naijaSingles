import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../data/models/event_model.dart';

class EventDetailsSliverAppBar extends StatelessWidget {
  const EventDetailsSliverAppBar({
    required this.event,
    required this.onShare,
    super.key,
  });

  final EventModel event;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => SliverAppBar(
        expandedHeight: 350,
        pinned: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Go back',
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Share event',
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Colors.white, size: 20),
                onPressed: onShare,
              ),
            ),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              _buildHeaderImage(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        event.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildChip(
                          label: event.category,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          label: event.isFree ? 'FREE'.tr() : 'PAID'.tr(),
                          color: event.isFree
                              ? Colors.grey.withValues(alpha: 0.8)
                              : const Color(0xFFEF476F).withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildChip({required String label, required Color color}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  Widget _buildHeaderImage() {
    final imageUrl = event.imageUrl;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const ColoredBox(
          color: Color(0xFFF5F5F5),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() => ColoredBox(
        color: AppColors.primaryGreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(),
              size: 80,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              event.category,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );

  IconData _getCategoryIcon() {
    switch (event.category.toLowerCase()) {
      case 'music':
        return Icons.music_note;
      case 'business':
        return Icons.business;
      case 'community':
        return Icons.group;
      case 'food':
      case 'food & drink':
        return Icons.restaurant;
      case 'arts':
        return Icons.palette;
      case 'fashion':
        return Icons.checkroom;
      case 'sports':
      case 'fitness':
        return Icons.sports;
      case 'technology':
        return Icons.computer;
      default:
        return Icons.event;
    }
  }
}
