import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';

class ModernProfileCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onConnect;
  final VoidCallback? onTap;

  const ModernProfileCard({
    Key? key,
    required this.user,
    this.onConnect,
    this.onTap,
  }) : super(key: key);

  @override
  State<ModernProfileCard> createState() => _ModernProfileCardState();
}

class _ModernProfileCardState extends State<ModernProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.user.imageUrl ?? [];
    final primaryPhoto = photos.isNotEmpty ? photos[0] : null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E5), // Cream background
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF008037).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero-style full-width photo
                  _buildHeroPhoto(primaryPhoto, photos.length),
                  
                  // Profile information
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name, age, and active status
                        _buildNameAndStatus(),
                        
                        const SizedBox(height: 12),
                        
                        // Nationality & Tribe tags
                        _buildNationalityTribeTags(),
                        
                        const SizedBox(height: 12),
                        
                        // Interests badges
                        _buildInterestsBadges(),
                        
                        const SizedBox(height: 20),
                        
                        // Connect button
                        _buildConnectButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPhoto(String? photoUrl, int photoCount) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Handle image loading error
                },
              )
            : null,
        color: photoUrl == null ? Colors.grey[300] : null,
      ),
      child: Stack(
        children: [
          // Photo count indicator
          if (photoCount > 1)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$photoCount',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Tap to view indicator
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF008037),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF008037).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          
          // Photo dots indicator
          if (photoCount > 1)
            Positioned(
              bottom: 16,
              left: 16,
              child: Row(
                children: List.generate(
                  photoCount > 5 ? 5 : photoCount,
                  (index) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNameAndStatus() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "${widget.user.name ?? 'Unknown'}, ${widget.user.age ?? 'N/A'}",
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        // Active status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF008037),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNationalityTribeTags() {
    final nationality = widget.user.nationality ?? 'Nigerian';
    final tribe = widget.user.tribe ?? 'Yoruba';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF008037).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '🇳🇬 $nationality',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF008037),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF008037).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '• $tribe',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF008037),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsBadges() {
    // Extract interests from user data
    final interests = <String>[];
    
    // Add default interests or extract from user data
    if (widget.user.editInfo != null) {
      final userBio = widget.user.editInfo!['userBio']?.toString() ?? '';
      if (userBio.toLowerCase().contains('music')) interests.add('Music');
      if (userBio.toLowerCase().contains('travel')) interests.add('Travel');
      if (userBio.toLowerCase().contains('food')) interests.add('Food');
    }
    
    // Add default interests if none found
    if (interests.isEmpty) {
      interests.addAll(['Dating', 'Music', 'Travel']);
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.take(3).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            interest,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.onConnect,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008037),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Connect',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
