import 'package:flutter/material.dart';

/// Custom 3D-style icons with modern glossy aesthetic
/// Inspired by contemporary app design trends
class Custom3DIcons {
  // Prevent instantiation
  Custom3DIcons._();

  // 🏠 NAVIGATION ICONS - 3D Style
  static Widget communities({double size = 24, Color? color}) => _build3DIcon(
        Icons.diversity_3_rounded,
        size: size,
        color: color ?? const Color(0xFF008037),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget connect({double size = 24, Color? color}) => _build3DIcon(
        Icons.favorite_rounded,
        size: size,
        color: color ?? const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget messages({double size = 24, Color? color}) => _build3DIcon(
        Icons.chat_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget profile({double size = 24, Color? color}) => _build3DIcon(
        Icons.person_rounded,
        size: size,
        color: color ?? const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎯 COMMUNITIES HUB ICONS - 3D Style
  static Widget events({double size = 24, Color? color}) => _build3DIcon(
        Icons.celebration_rounded,
        size: size,
        color: color ?? const Color(0xFFFF9800),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget groups({double size = 24, Color? color}) => _build3DIcon(
        Icons.groups_rounded,
        size: size,
        color: color ?? const Color(0xFF6B46C1),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF5A2D91)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget learning({double size = 24, Color? color}) => _build3DIcon(
        Icons.auto_stories_rounded,
        size: size,
        color: color ?? const Color(0xFF059669),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget networking({double size = 24, Color? color}) => _build3DIcon(
        Icons.handshake_rounded,
        size: size,
        color: color ?? const Color(0xFFDC2626),
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎨 TAB ICONS - 3D Style
  static Widget discover({double size = 24, Color? color}) => _build3DIcon(
        Icons.explore_rounded,
        size: size,
        color: color ?? const Color(0xFF00BCD4),
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget groupsTab({double size = 24, Color? color}) => _build3DIcon(
        Icons.group_rounded,
        size: size,
        color: color ?? const Color(0xFF673AB7),
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget learningTab({double size = 24, Color? color}) => _build3DIcon(
        Icons.school_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget networkingTab({double size = 24, Color? color}) => _build3DIcon(
        Icons.business_rounded,
        size: size,
        color: color ?? const Color(0xFF607D8B),
        gradient: const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // ⚡ ACTION ICONS - 3D Style
  static Widget createEvent({double size = 24, Color? color}) => _build3DIcon(
        Icons.add_circle_rounded,
        size: size,
        color: color ?? const Color(0xFF008037),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget search({double size = 24, Color? color}) => _build3DIcon(
        Icons.search_rounded,
        size: size,
        color: color ?? const Color(0xFF757575),
        gradient: const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget settings({double size = 24, Color? color}) => _build3DIcon(
        Icons.settings_rounded,
        size: size,
        color: color ?? const Color(0xFF795548),
        gradient: const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFF5D4037)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget edit({double size = 24, Color? color}) => _build3DIcon(
        Icons.edit_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget location({double size = 24, Color? color}) => _build3DIcon(
        Icons.location_on_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget age({double size = 24, Color? color}) => _build3DIcon(
        Icons.cake_rounded,
        size: size,
        color: color ?? const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget notification({double size = 24, Color? color}) => _build3DIcon(
        Icons.notifications_rounded,
        size: size,
        color: color ?? const Color(0xFFFF5722),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🌍 CULTURAL ICONS - 3D Style
  static Widget culturalHeritage({double size = 24, Color? color}) =>
      _build3DIcon(
        Icons.account_tree_rounded,
        size: size,
        color: color ?? const Color(0xFF8D6E63),
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget language({double size = 24, Color? color}) => _build3DIcon(
        Icons.translate_rounded,
        size: size,
        color: color ?? const Color(0xFF3F51B5),
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget traditions({double size = 24, Color? color}) => _build3DIcon(
        Icons.festival_rounded,
        size: size,
        color: color ?? const Color(0xFFFFC107),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget community({double size = 24, Color? color}) => _build3DIcon(
        Icons.diversity_3_rounded,
        size: size,
        color: color ?? const Color(0xFF009688),
        gradient: const LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF00695C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 💕 SOCIAL ICONS - 3D Style
  static Widget like({double size = 24, Color? color}) => _build3DIcon(
        Icons.favorite_rounded,
        size: size,
        color: color ?? const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget star({double size = 24, Color? color}) => _build3DIcon(
        Icons.star_rounded,
        size: size,
        color: color ?? const Color(0xFFFFD700),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget heart({double size = 24, Color? color}) => _build3DIcon(
        Icons.favorite_rounded,
        size: size,
        color: color ?? const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎯 STATUS ICONS - 3D Style
  static Widget verified({double size = 24, Color? color}) => _build3DIcon(
        Icons.verified_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget premium({double size = 24, Color? color}) => _build3DIcon(
        Icons.diamond_rounded,
        size: size,
        color: color ?? const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🔧 UTILITY ICONS - 3D Style
  static Widget back({double size = 24, Color? color}) => _build3DIcon(
        Icons.arrow_back_rounded,
        size: size,
        color: color ?? const Color(0xFF757575),
        gradient: const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget forward({double size = 24, Color? color}) => _build3DIcon(
        Icons.arrow_forward_rounded,
        size: size,
        color: color ?? const Color(0xFF757575),
        gradient: const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF616161)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget close({double size = 24, Color? color}) => _build3DIcon(
        Icons.close_rounded,
        size: size,
        color: color ?? const Color(0xFFF44336),
        gradient: const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget check({double size = 24, Color? color}) => _build3DIcon(
        Icons.check_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎨 CREATIVE ICONS - 3D Style
  static Widget camera({double size = 24, Color? color}) => _build3DIcon(
        Icons.camera_alt_rounded,
        size: size,
        color: color ?? const Color(0xFF607D8B),
        gradient: const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget image({double size = 24, Color? color}) => _build3DIcon(
        Icons.image_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget music({double size = 24, Color? color}) => _build3DIcon(
        Icons.music_note_rounded,
        size: size,
        color: color ?? const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget art({double size = 24, Color? color}) => _build3DIcon(
        Icons.brush_rounded,
        size: size,
        color: color ?? const Color(0xFFFF9800),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🏢 PROFESSIONAL ICONS - 3D Style
  static Widget business({double size = 24, Color? color}) => _build3DIcon(
        Icons.business_rounded,
        size: size,
        color: color ?? const Color(0xFF37474F),
        gradient: const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF263238)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget work({double size = 24, Color? color}) => _build3DIcon(
        Icons.work_rounded,
        size: size,
        color: color ?? const Color(0xFF455A64),
        gradient: const LinearGradient(
          colors: [Color(0xFF455A64), Color(0xFF37474F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget skills({double size = 24, Color? color}) => _build3DIcon(
        Icons.build_rounded,
        size: size,
        color: color ?? const Color(0xFF795548),
        gradient: const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFF5D4037)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎓 LEARNING ICONS - 3D Style
  static Widget book({double size = 24, Color? color}) => _build3DIcon(
        Icons.book_rounded,
        size: size,
        color: color ?? const Color(0xFF3F51B5),
        gradient: const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF303F9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget school({double size = 24, Color? color}) => _build3DIcon(
        Icons.school_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget knowledge({double size = 24, Color? color}) => _build3DIcon(
        Icons.lightbulb_rounded,
        size: size,
        color: color ?? const Color(0xFFFFC107),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🌟 SPECIAL ICONS - 3D Style
  static Widget sparkle({double size = 24, Color? color}) => _build3DIcon(
        Icons.auto_awesome_rounded,
        size: size,
        color: color ?? const Color(0xFFFFD700),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget magic({double size = 24, Color? color}) => _build3DIcon(
        Icons.auto_fix_high_rounded,
        size: size,
        color: color ?? const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget celebration({double size = 24, Color? color}) => _build3DIcon(
        Icons.celebration_rounded,
        size: size,
        color: color ?? const Color(0xFFFF5722),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🏃‍♂️ LIFESTYLE ICONS - 3D Style
  static Widget fitness({double size = 24, Color? color}) => _build3DIcon(
        Icons.fitness_center_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget health({double size = 24, Color? color}) => _build3DIcon(
        Icons.health_and_safety_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget sports({double size = 24, Color? color}) => _build3DIcon(
        Icons.sports_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🍽️ FOOD ICONS - 3D Style
  static Widget food({double size = 24, Color? color}) => _build3DIcon(
        Icons.restaurant_rounded,
        size: size,
        color: color ?? const Color(0xFFFF9800),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget cooking({double size = 24, Color? color}) => _build3DIcon(
        Icons.restaurant_menu_rounded,
        size: size,
        color: color ?? const Color(0xFF8D6E63),
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎵 ENTERTAINMENT ICONS - 3D Style
  static Widget movie({double size = 24, Color? color}) => _build3DIcon(
        Icons.movie_rounded,
        size: size,
        color: color ?? const Color(0xFF9C27B0),
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget theater({double size = 24, Color? color}) => _build3DIcon(
        Icons.theater_comedy_rounded,
        size: size,
        color: color ?? const Color(0xFFFF9800),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🌍 TRAVEL ICONS - 3D Style
  static Widget travel({double size = 24, Color? color}) => _build3DIcon(
        Icons.flight_rounded,
        size: size,
        color: color ?? const Color(0xFF00BCD4),
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget adventure({double size = 24, Color? color}) => _build3DIcon(
        Icons.explore_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget map({double size = 24, Color? color}) => _build3DIcon(
        Icons.map_rounded,
        size: size,
        color: color ?? const Color(0xFF607D8B),
        gradient: const LinearGradient(
          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // 🎯 GOAL ICONS - 3D Style
  static Widget target({double size = 24, Color? color}) => _build3DIcon(
        Icons.gps_fixed_rounded,
        size: size,
        color: color ?? const Color(0xFFE91E63),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget achievement({double size = 24, Color? color}) => _build3DIcon(
        Icons.emoji_events_rounded,
        size: size,
        color: color ?? const Color(0xFFFFD700),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget progress({double size = 24, Color? color}) => _build3DIcon(
        Icons.trending_up_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // Helper method to build 3D-style icons
  static Widget _build3DIcon(
    IconData iconData, {
    required double size,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: size,
        color: Colors.white,
      ),
    );
  }

  // 🌍 CULTURAL & COMMUNITY ICONS
  static Widget culture({double size = 24, Color? color}) => _build3DIcon(
        Icons.public_rounded,
        size: size,
        color: color ?? const Color(0xFF8D6E63),
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget translate({double size = 24, Color? color}) => _build3DIcon(
        Icons.translate_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget message({double size = 24, Color? color}) => _build3DIcon(
        Icons.chat_bubble_outline_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget save({double size = 24, Color? color}) => _build3DIcon(
        Icons.bookmark_outline_rounded,
        size: size,
        color: color ?? const Color(0xFFFF9800),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget block({double size = 24, Color? color}) => _build3DIcon(
        Icons.block_rounded,
        size: size,
        color: color ?? const Color(0xFFF44336),
        gradient: const LinearGradient(
          colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget filter({double size = 24, Color? color}) => _build3DIcon(
        Icons.tune_rounded,
        size: size,
        color: color ?? const Color(0xFF9E9E9E),
        gradient: const LinearGradient(
          colors: [Color(0xFF9E9E9E), Color(0xFF757575)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  // ➕ ADDITIONAL ICONS FOR GROUPS FEATURE
  static Widget add({double size = 24, Color? color}) => _build3DIcon(
        Icons.add_rounded,
        size: size,
        color: color ?? const Color(0xFF4CAF50),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget public({double size = 24, Color? color}) => _build3DIcon(
        Icons.public_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  static Widget chat({double size = 24, Color? color}) => _build3DIcon(
        Icons.chat_rounded,
        size: size,
        color: color ?? const Color(0xFF2196F3),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
}
