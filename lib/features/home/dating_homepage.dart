import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DatingHomePage extends StatelessWidget {
  const DatingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFDF6EC);
    const deepBrown = Color(0xFF4E342E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dating',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: deepBrown,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: deepBrown),
            onPressed: () {},
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'asset/auth/profile_placeholder.png',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ada, 27',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: deepBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lagos',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag('Yoruba'),
                      _buildTag('Advertising'),
                      _buildTag('Entrepreneur'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Suggested Matches
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suggested Matches',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepBrown,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                )
              ],
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'asset/auth/profile_placeholder.png',
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Thea, 25',
                            style: GoogleFonts.poppins(fontSize: 12))
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Interests
            Text(
              'Interests',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: deepBrown,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag('Movies'),
                _buildTag('Cooking'),
                _buildTag('Fitness'),
                _buildTag('Poetry'),
                _buildTag('Tech'),
                _buildTag('Volunteering'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
