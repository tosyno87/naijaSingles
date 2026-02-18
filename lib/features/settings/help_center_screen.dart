import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/constants/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // Afropeep MVP Color Scheme
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Color(0xFFFFFFFF); // White for cards
  static final Color textPrimary = Colors.brown.shade800;
  static final Color textSecondary = Colors.brown.shade600;
  static final Color textLight = Colors.grey.shade600;

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['FAQ', 'Contact', 'Guides'];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundColor,
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
    final faqSections = [
      {
        'category': 'Getting Started',
        'icon': Icons.rocket_launch,
        'items': [
          {
            'question': 'How do I create a profile?',
            'answer':
                'Tap on the Profile tab and fill in your basic information, add photos, and write a bio that represents you. A complete profile helps you connect with the right people.',
          },
          {
            'question': 'What can I do on Afropeep?',
            'answer':
                'Afropeep is a community platform for Africans in the diaspora. You can discover and connect with new people, join communities, attend events, and build meaningful relationships.',
          },
        ],
      },
      {
        'category': 'Discover & Connect',
        'icon': Icons.explore,
        'items': [
          {
            'question': 'How does the Discover screen work?',
            'answer':
                'The Discover screen shows you profiles based on your location, preferences, and interests. Swipe right to like someone or left to pass. When two people like each other, it\'s a match!',
          },
          {
            'question': 'Can I change my location or distance preferences?',
            'answer':
                'Yes! Go to Settings > Location to update your location. You can also adjust your distance range and other preferences to refine who appears in your Discover feed.',
          },
          {
            'question': 'What is a Super Like?',
            'answer':
                'A Super Like lets someone know you\'re especially interested. It stands out from a regular like and can help you get noticed.',
          },
        ],
      },
      {
        'category': 'Communities',
        'icon': Icons.groups,
        'items': [
          {
            'question': 'What are Communities?',
            'answer':
                'Communities are groups where you can connect with people who share your interests, culture, or location. Join existing communities or create your own to bring people together.',
          },
          {
            'question': 'How do I join or create a Community?',
            'answer':
                'Go to the Communities tab to browse and join existing groups. To create your own, tap the "+" button and set a name, description, and guidelines for your community.',
          },
          {
            'question': 'Can I leave a Community?',
            'answer':
                'Yes. Open the community, tap the settings or menu icon, and select "Leave Community." You can rejoin at any time.',
          },
        ],
      },
      {
        'category': 'Events',
        'icon': Icons.event,
        'items': [
          {
            'question': 'How do I find events near me?',
            'answer':
                'Go to the Events tab to browse upcoming events. You can filter by location, date, and category to find events that interest you.',
          },
          {
            'question': 'How do I RSVP to an event?',
            'answer':
                'Tap on any event to view its details, then tap "RSVP" to confirm your attendance. You\'ll receive a reminder as the event date approaches.',
          },
          {
            'question': 'Can I create my own event?',
            'answer':
                'Yes! Tap the "+" button on the Events tab to create an event. Add a title, description, date, location, and optional cover image to share with the community.',
          },
        ],
      },
      {
        'category': 'Messages & Notifications',
        'icon': Icons.chat_bubble,
        'items': [
          {
            'question': 'How do I start a conversation?',
            'answer':
                'Once you match with someone, go to your Messages tab and tap on their profile to begin chatting. Be respectful and genuine!',
          },
          {
            'question': 'How do I change my notification settings?',
            'answer':
                'Go to Settings > Notifications to choose which notifications you receive — matches, messages, community updates, event reminders, and more.',
          },
          {
            'question': 'Can I mute a conversation?',
            'answer':
                'Yes. Open the conversation, tap the menu icon, and select "Mute." You\'ll still receive messages but won\'t get push notifications for that thread.',
          },
        ],
      },
      {
        'category': 'Account & Privacy',
        'icon': Icons.shield,
        'items': [
          {
            'question': 'How do I pause or hide my profile?',
            'answer':
                'Go to Settings > Take a Break. You can pause your account or go incognito. Your profile won\'t appear in Discover, but your existing matches and chats stay intact. Reactivate anytime.',
          },
          {
            'question': 'How do I delete my account?',
            'answer':
                'Go to Settings > Delete Account. Please note that this action is permanent and cannot be undone. Consider pausing your account first if you just need a break.',
          },
          {
            'question': 'Is my personal information safe?',
            'answer':
                'Yes. We use encryption to protect your data and never share your personal information with third parties. You control what\'s visible on your profile.',
          },
        ],
      },
      {
        'category': 'Safety & Reporting',
        'icon': Icons.security,
        'items': [
          {
            'question': 'How do I report someone?',
            'answer':
                'Go to the person\'s profile and tap the report button. You can also report inappropriate content in communities or events. We investigate all reports seriously.',
          },
          {
            'question': 'How do I block someone?',
            'answer':
                'Go to their profile and tap the block button. Blocked users won\'t be able to see your profile or message you.',
          },
          {
            'question': 'What should I do if I encounter a bug?',
            'answer':
                'Report it through Settings > Send Feedback. Include as much detail as possible (what you were doing, what happened) to help us fix it quickly.',
          },
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqSections.length,
      itemBuilder: (context, index) {
        final section = faqSections[index];
        final items = section['items'] as List<Map<String, String>>;
        return _buildFAQSection(
          category: section['category'] as String,
          icon: section['icon'] as IconData,
          items: items,
        );
      },
    );
  }

  Widget _buildFAQSection({
    required String category,
    required IconData icon,
    required List<Map<String, String>> items,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(_buildFAQItem),
          const SizedBox(height: 8),
        ],
      );

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
                    'We typically respond to emails within 24-48 hours during business days (Monday to Friday, 9 AM – 6 PM EST).',
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
        'icon': Icons.rocket_launch,
        'title': 'Getting Started',
        'description': 'Set up your profile and explore Afropeep',
        'steps': [
          'Create your account with email or phone',
          'Add your best photos (at least 3)',
          'Write an engaging bio that shows your personality',
          'Set your preferences for discovery',
          'Explore Discover, Communities, and Events',
        ],
      },
      {
        'icon': Icons.explore,
        'title': 'Making Meaningful Connections',
        'description': 'Tips for connecting with the right people',
        'steps': [
          'Be authentic in your profile',
          'Use recent, clear photos',
          'Write a genuine bio',
          'Be respectful in all conversations',
          'Take time to read profiles before swiping',
        ],
      },
      {
        'icon': Icons.groups,
        'title': 'Communities',
        'description': 'Find your tribe and build lasting connections',
        'steps': [
          'Browse communities by interest, culture, or location',
          'Join communities that resonate with you',
          'Introduce yourself and participate in discussions',
          'Create your own community around a shared interest',
          'Invite friends and grow your network',
        ],
      },
      {
        'icon': Icons.event,
        'title': 'Events',
        'description': 'Discover and attend events in the diaspora',
        'steps': [
          'Browse upcoming events in the Events tab',
          'Filter by location, date, or category',
          'RSVP to events you want to attend',
          'Create your own event and invite the community',
          'Check in and connect with attendees',
        ],
      },
      {
        'icon': Icons.chat,
        'title': 'Messaging',
        'description': 'Stay in touch with your connections',
        'steps': [
          'Open Messages to see all your conversations',
          'Tap a match to start or continue chatting',
          'Use photos and expressive messages',
          'Be genuine, respectful, and show interest',
          'Manage notifications in Settings if needed',
        ],
      },
      {
        'icon': Icons.settings,
        'title': 'Account Management',
        'description': 'Control your profile, privacy, and visibility',
        'steps': [
          'Edit your profile anytime from the Profile tab',
          'Adjust discovery preferences in Settings',
          'Pause your account or go incognito for a break',
          'Manage blocked users in Settings > Blocked Users',
          'Delete your account permanently in Settings if needed',
        ],
      },
      {
        'icon': Icons.security,
        'title': 'Staying Safe',
        'description': 'Important safety tips for the community',
        'steps': [
          'Keep personal info private until you feel comfortable',
          'Meet in public places when connecting in person',
          'Tell someone you trust about your plans',
          'Trust your instincts — if something feels off, step back',
          'Report inappropriate behavior in profiles, chats, or communities',
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
