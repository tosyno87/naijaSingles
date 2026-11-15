import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';

/// Figma `4:3` — dark Houston hero. Locals copy is passed in so the parent
/// can default to the honest label and upgrade after verification.
class HoustonHomeHero extends StatelessWidget {
  const HoustonHomeHero({
    required this.localsLabel,
    required this.showVerifiedMark,
    required this.onSeeThisWeekend,
    required this.onProfileTap,
    this.profilePhotoUrl,
    this.localPhotoUrls = const <String>[],
    super.key,
  });

  static const Color heroBackground = Color(0xFF050807);
  static const Color subheadGreen = Color(0xFF12B863);
  static const String honestLocalsLabel = 'People showing up this week';
  static const String verifiedLocalsLabel = 'Verified locals';

  final String localsLabel;
  final bool showVerifiedMark;
  final VoidCallback onSeeThisWeekend;
  final VoidCallback onProfileTap;
  final String? profilePhotoUrl;
  final List<String> localPhotoUrls;

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: heroBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topInset + 8, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AfroPeep',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Profile',
                  child: InkWell(
                    onTap: onProfileTap,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _AvatarCircle(
                          url: profilePhotoUrl,
                          size: 36,
                          fallbackColor: const Color(0xFF8D6E63),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: heroBackground),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'New in Houston?\nMeet your people.',
              style: GoogleFonts.montserrat(
                fontSize: 29,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This weekend in Houston',
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: subheadGreen,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _OverlappingAvatars(urls: localPhotoUrls),
                if (showVerifiedMark) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: subheadGreen,
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localsLabel,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                onPressed: onSeeThisWeekend,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'See this weekend',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlappingAvatars extends StatelessWidget {
  const _OverlappingAvatars({required this.urls});

  final List<String> urls;

  static const List<Color> _fallbacks = <Color>[
    Color(0xFF8D6E63),
    Color(0xFFE8A0B0),
    Color(0xFF5B8A8A),
    Color(0xFFC4A574),
  ];

  @override
  Widget build(BuildContext context) {
    final int count = urls.isEmpty ? 4 : urls.take(4).length;
    const double size = 31;
    const double overlap = 6;
    return SizedBox(
      width: size + (count - 1) * (size - overlap),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              left: i * (size - overlap),
              child: _AvatarCircle(
                url: i < urls.length ? urls[i] : null,
                size: size,
                fallbackColor: _fallbacks[i % _fallbacks.length],
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.size,
    required this.fallbackColor,
    this.url,
  });

  final String? url;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final String? photo = url;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: photo,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            )
          : null,
    );
  }
}
