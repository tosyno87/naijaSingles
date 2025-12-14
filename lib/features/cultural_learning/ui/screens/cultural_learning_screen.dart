import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/constants/app_colors.dart';
import '../widgets/cultural_story_card.dart';
import '../widgets/language_exchange_card.dart';

class CulturalLearningScreen extends StatefulWidget {
  const CulturalLearningScreen({Key? key}) : super(key: key);

  @override
  State<CulturalLearningScreen> createState() => _CulturalLearningScreenState();
}

class _CulturalLearningScreenState extends State<CulturalLearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCulturalStoriesTab(),
                  _buildLanguageExchangeTab(),
                  _buildCulturalEventsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Culture Corner',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Learn, share, and celebrate African cultures',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF008037),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Stories'),
          Tab(text: 'Language'),
          Tab(text: 'Events'),
        ],
      ),
    );
  }

  Widget _buildCulturalStoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CulturalStoryCard(
          title: 'The Art of Nigerian Jollof Rice',
          author: 'Amina Okafor',
          country: 'Nigeria',
          category: 'Food',
          content:
              'Discover the secrets behind Nigeria\'s most beloved dish. From the perfect rice-to-tomato ratio to the traditional cooking methods passed down through generations...',
          likesCount: 234,
          commentsCount: 45,
          isVerified: true,
          onLike: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liked this story!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        CulturalStoryCard(
          title: 'Ghanaian Kente Weaving Traditions',
          author: 'Kwame Asante',
          country: 'Ghana',
          category: 'Traditions',
          content:
              'Learn about the ancient art of Kente weaving, its cultural significance, and the stories woven into each pattern. A journey through Ghana\'s textile heritage...',
          likesCount: 189,
          commentsCount: 32,
          isVerified: true,
          onLike: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liked this story!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        CulturalStoryCard(
          title: 'Kenyan Maasai Beadwork Patterns',
          author: 'Naisula Lekishon',
          country: 'Kenya',
          category: 'Art',
          content:
              'Explore the intricate world of Maasai beadwork, where every color and pattern tells a story of community, age, and social status...',
          likesCount: 156,
          commentsCount: 28,
          isVerified: false,
          onLike: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liked this story!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageExchangeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LanguageExchangeCard(
          nativeLanguage: 'Yoruba',
          learningLanguage: 'English',
          userName: 'Folake Adebayo',
          country: 'Nigeria',
          city: 'Lagos',
          proficiency: 'Advanced',
          description:
              'Native Yoruba speaker looking to help others learn while improving my English. Love discussing culture and traditions!',
          isOnline: true,
          isInPerson: false,
          onConnect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection request sent!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        LanguageExchangeCard(
          nativeLanguage: 'English',
          learningLanguage: 'Swahili',
          userName: 'Marcus Johnson',
          country: 'USA',
          city: 'New York',
          proficiency: 'Beginner',
          description:
              'American learning Swahili for travel to East Africa. Would love to practice with native speakers and learn about the culture.',
          isOnline: true,
          isInPerson: true,
          onConnect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection request sent!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        LanguageExchangeCard(
          nativeLanguage: 'Twi',
          learningLanguage: 'French',
          userName: 'Akosua Mensah',
          country: 'Ghana',
          city: 'Accra',
          proficiency: 'Intermediate',
          description:
              'Ghanaian Twi speaker learning French for business opportunities. Happy to share Twi culture and language in exchange.',
          isOnline: true,
          isInPerson: false,
          onConnect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection request sent!'),
                backgroundColor: Color(0xFF008037),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCulturalEventsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Cultural Events',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover cultural events and celebrations\ncoming soon!',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
