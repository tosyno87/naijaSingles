import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

class PeopleCard extends StatelessWidget {
  const PeopleCard({
    required this.user,
    required this.onTap,
    super.key,
  });

  final UserModel user;
  final VoidCallback onTap;

  String? get _photoUrl {
    final images = user.imageUrl;
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first.isNotEmpty) return first;
    }
    return null;
  }

  String get _flagEmoji {
    const flags = <String, String>{
      'Nigeria': '🇳🇬',
      'Ghana': '🇬🇭',
      'Kenya': '🇰🇪',
      'South Africa': '🇿🇦',
      'Ethiopia': '🇪🇹',
      'Tanzania': '🇹🇿',
      'Uganda': '🇺🇬',
      'Cameroon': '🇨🇲',
      'Senegal': '🇸🇳',
      'Ivory Coast': '🇨🇮',
      'Morocco': '🇲🇦',
      'Egypt': '🇪🇬',
      'Mali': '🇲🇱',
    };
    final nat = user.nationality;
    if (nat != null && flags.containsKey(nat)) return flags[nat]!;
    return '🌍';
  }

  String get _subtitle {
    if (user.profession != null && user.profession!.isNotEmpty) {
      return user.profession!;
    }
    if (user.lookingFor != null && user.lookingFor!.isNotEmpty) {
      return user.lookingFor!;
    }
    if (user.living_in != null && user.living_in!.isNotEmpty) {
      return user.living_in!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${user.name ?? "User"} profile',
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_photoUrl != null)
                  CachedNetworkImage(
                    imageUrl: _photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
                  )
                else
                  ColoredBox(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),

                // Bottom gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.5, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                ),

                // Heart icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Color(0xFFE8475F),
                    ),
                  ),
                ),

                // Bottom info
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            _flagEmoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          if (user.age != null)
                            Text(
                              '${user.age}',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.name ?? 'Unknown',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _subtitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
