import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/custom_3d_icons.dart';
import '../../../groups/screens/unified_groups_screen.dart';

class CommunitiesHubScreen extends StatefulWidget {
  const CommunitiesHubScreen({super.key});

  @override
  State<CommunitiesHubScreen> createState() => _CommunitiesHubScreenState();
}

class _CommunitiesHubScreenState extends State<CommunitiesHubScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Discover',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.backgroundColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      );

  Widget _buildQuickActions() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Afropeep',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Events',
                  'Find parties, celebrations, and local events',
                  Custom3DIcons.events(),
                  const Color(0xFF008037), // Green accent
                  () {
                    Navigator.pushNamed(context, RouteName.eventsScreen);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Communities',
                  'Join communities and connect with people',
                  Custom3DIcons.groups(),
                  const Color(0xFF008037), // Green accent
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UnifiedGroupsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildActionCard(
    String title,
    String subtitle,
    Widget icon,
    Color color,
    VoidCallback? onTap,
  ) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: color.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: icon,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: const Color(0xFF666666),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
}
