import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // Afropeep MVP Color Scheme
  static const Color backgroundColor = Colors.white; // Clean white
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['FAQ', 'Contact', 'Guides'];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Help Center',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Tab Bar
            _buildTabBar(),

            // Tab Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: _tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = index == _selectedTabIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTabIndex = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tab,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFAQTab();
      case 1:
        return _buildContactTab();
      case 2:
        return _buildGuidesTab();
      default:
        return _buildFAQTab();
    }
  }

  Widget _buildFAQTab() {
    final faqs = [
      {
        'question': 'How do I create a profile?',
        'answer':
            'To create your profile, tap on the profile icon and fill in your basic information, add photos, and write a bio that represents you.',
      },
      {
        'question': 'How does matching work?',
        'answer':
            'Our matching system shows you potential matches based on your location, age preferences, and interests. Swipe right to like someone or left to pass.',
      },
      {
        'question': 'How do I start a conversation?',
        'answer':
            'Once you match with someone, you can start chatting! Go to your Messages tab and tap on their profile to begin the conversation.',
      },
      {
        'question': 'Can I change my location?',
        'answer':
            'Yes! Go to Settings > Location to update your location settings. You can also enable location services for more accurate matching.',
      },
      {
        'question': 'How do I report someone?',
        'answer':
            'If someone is behaving inappropriately, go to their profile and tap the report button. We take all reports seriously and will investigate.',
      },
      {
        'question': 'How do I block someone?',
        'answer':
            'To block someone, go to their profile and tap the block button. Blocked users won\'t be able to see your profile or message you.',
      },
      {
        'question': 'How do I delete my account?',
        'answer':
            'Go to Settings > Account > Delete Account. Please note that this action is permanent and cannot be undone.',
      },
      {
        'question': 'Is my personal information safe?',
        'answer':
            'Yes, we take your privacy seriously. We use encryption to protect your data and never share your personal information with third parties.',
      },
      {
        'question': 'How do I change my notification settings?',
        'answer':
            'Go to Settings > Notifications to customize which notifications you receive and when you receive them.',
      },
      {
        'question': 'What should I do if I encounter a bug?',
        'answer':
            'If you find a bug, please report it through Settings > Send Feedback. Include as much detail as possible to help us fix it quickly.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) => _buildFAQItem(faqs[index]),
    );
  }

  Widget _buildFAQItem(Map<String, String> faq) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          title: Text(
            faq['question']!,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          iconColor: primaryColor,
          collapsedIconColor: textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['answer']!,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildContactTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Get in Touch',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re here to help! Send us an email and we\'ll get back to you as soon as possible.',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Email Support Option
            _buildContactOption(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'Get help via email',
              description: 'support@afropeep.com',
              onTap: () => _sendEmail('support@afropeep.com'),
            ),

            const SizedBox(height: 16),

            // Send Feedback Option
            _buildContactOption(
              icon: Icons.feedback,
              title: 'Send Feedback',
              subtitle: 'Share your thoughts',
              description: 'Help us improve the app',
              onTap: () => Navigator.pushNamed(context, '/feedback'),
            ),

            const SizedBox(height: 24),

            // Support Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Response Time',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We typically respond to emails within 24-48 hours during business days (Monday to Friday, 9 AM - 6 PM WAT).',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: textLight,
                size: 16,
              ),
            ],
          ),
        ),
      );

  Widget _buildGuidesTab() {
    final guides = [
      {
        'icon': Icons.person_add,
        'title': 'Getting Started',
        'description': 'Learn how to set up your profile and start matching',
        'steps': [
          'Create your account with email or phone',
          'Add your best photos (at least 3)',
          'Write an engaging bio',
          'Set your preferences',
          'Start swiping and matching!',
        ],
      },
      {
        'icon': Icons.favorite,
        'title': 'Making Great Matches',
        'description': 'Tips for finding meaningful connections',
        'steps': [
          'Be authentic in your profile',
          'Use recent, clear photos',
          'Write a genuine bio',
          'Be respectful in conversations',
          'Take time to read profiles',
        ],
      },
      {
        'icon': Icons.chat,
        'title': 'Starting Conversations',
        'description': 'How to break the ice and keep conversations flowing',
        'steps': [
          'Read their profile for conversation starters',
          'Ask open-ended questions',
          'Share something about yourself',
          'Be genuine and show interest',
          'Suggest meeting in person when ready',
        ],
      },
      {
        'icon': Icons.security,
        'title': 'Staying Safe',
        'description': 'Important safety tips for online dating',
        'steps': [
          'Meet in public places first',
          'Tell someone your plans',
          'Trust your instincts',
          'Keep personal info private initially',
          'Report inappropriate behavior',
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      itemBuilder: (context, index) => _buildGuideItem(guides[index]),
    );
  }

  Widget _buildGuideItem(Map<String, dynamic> guide) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ExpansionTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(guide['icon'], color: primaryColor, size: 24),
          ),
          title: Text(
            guide['title'],
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Text(
            guide['description'],
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
          iconColor: primaryColor,
          collapsedIconColor: textSecondary,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (guide['steps'] as List<String>)
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key + 1;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Afropeep Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not open email app');
      }
    } catch (e) {
      log('Error opening email: $e');
      _showErrorSnackBar('Could not open email app');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
