import '../models/enhanced_event_model.dart';

class EventTemplatesService {
  static List<EventTemplate> getAfrocentricTemplates() {
    return [
      EventTemplate(
        id: 'afrobeats_party',
        name: 'Afrobeats Party',
        description: 'Dance the night away to the hottest Afrobeats hits',
        category: 'Music',
        icon: '🎵',
        color: 0xFF8E24AA,
        suggestedDuration: const Duration(hours: 6),
        defaultData: _createEventData(
          name: 'Afrobeats Night',
          description: 'Join us for an unforgettable night of Afrobeats music, dancing, and good vibes. DJ will be spinning the latest hits from Nigeria, Ghana, and across Africa.',
          category: 'Music',
          tags: ['afrobeats', 'music', 'dance', 'nightlife', 'african'],
        ),
      ),
      
      EventTemplate(
        id: 'cultural_exhibition',
        name: 'Cultural Exhibition',
        description: 'Showcase African art, crafts, and heritage',
        category: 'Arts & Culture',
        icon: '🎨',
        color: 0xFF5E35B1,
        suggestedDuration: const Duration(days: 2),
        defaultData: _createEventData(
          name: 'African Heritage Exhibition',
          description: 'Discover the rich cultural heritage of Africa through art, crafts, and interactive displays. Meet local artists and learn about traditional practices.',
          category: 'Arts & Culture',
          tags: ['art', 'culture', 'heritage', 'exhibition', 'african'],
        ),
      ),
      
      EventTemplate(
        id: 'food_festival',
        name: 'Food Festival',
        description: 'Celebrate African cuisine and flavors',
        category: 'Food & Drink',
        icon: '🍽️',
        color: 0xFF43A047,
        suggestedDuration: const Duration(hours: 8),
        defaultData: _createEventData(
          name: 'African Food Festival',
          description: 'Taste authentic African dishes from different regions. Experience the diverse flavors of jollof rice, suya, injera, and many more traditional delicacies.',
          category: 'Food & Drink',
          tags: ['food', 'festival', 'cuisine', 'traditional', 'african'],
        ),
      ),
      
      EventTemplate(
        id: 'networking_meetup',
        name: 'Networking Meetup',
        description: 'Connect with the African diaspora community',
        category: 'Networking',
        icon: '🤝',
        color: 0xFF1E88E5,
        suggestedDuration: const Duration(hours: 3),
        defaultData: _createEventData(
          name: 'Diaspora Connect Meetup',
          description: 'Network with fellow Africans and friends of Africa. Share experiences, build connections, and strengthen our community bonds.',
          category: 'Networking',
          tags: ['networking', 'diaspora', 'community', 'professional', 'meetup'],
        ),
      ),
      
      EventTemplate(
        id: 'dance_workshop',
        name: 'Dance Workshop',
        description: 'Learn traditional and modern African dances',
        category: 'Sports & Fitness',
        icon: '💃',
        color: 0xFFFF7043,
        suggestedDuration: const Duration(hours: 2),
        defaultData: _createEventData(
          name: 'African Dance Workshop',
          description: 'Learn energetic African dance moves in a fun, supportive environment. Suitable for all skill levels. Come ready to move and groove!',
          category: 'Sports & Fitness',
          tags: ['dance', 'workshop', 'fitness', 'african', 'traditional'],
        ),
      ),
      
      EventTemplate(
        id: 'business_conference',
        name: 'Business Conference',
        description: 'African entrepreneurship and business development',
        category: 'Business',
        icon: '💼',
        color: 0xFF6D4C41,
        suggestedDuration: const Duration(hours: 8),
        defaultData: _createEventData(
          name: 'African Business Summit',
          description: 'Join entrepreneurs, investors, and business leaders to discuss opportunities in African markets. Network and learn from industry experts.',
          category: 'Business',
          tags: ['business', 'entrepreneurship', 'conference', 'networking', 'african'],
        ),
      ),
      
      EventTemplate(
        id: 'fashion_show',
        name: 'Fashion Show',
        description: 'Showcase African fashion and designers',
        category: 'Fashion',
        icon: '👗',
        color: 0xFFE91E63,
        suggestedDuration: const Duration(hours: 4),
        defaultData: _createEventData(
          name: 'African Fashion Showcase',
          description: 'Experience the beauty and creativity of African fashion. Featuring local designers, traditional wear, and contemporary African-inspired pieces.',
          category: 'Fashion',
          tags: ['fashion', 'design', 'showcase', 'african', 'style'],
        ),
      ),
      
      EventTemplate(
        id: 'book_club',
        name: 'Book Club',
        description: 'Discuss African literature and authors',
        category: 'Education',
        icon: '📚',
        color: 0xFF795548,
        suggestedDuration: const Duration(hours: 2),
        defaultData: _createEventData(
          name: 'African Literature Book Club',
          description: 'Join our monthly book club focusing on African authors and stories. Engage in thoughtful discussions about literature that celebrates African experiences.',
          category: 'Education',
          tags: ['books', 'literature', 'discussion', 'education', 'african'],
        ),
      ),
    ];
  }
  
  static EventTemplate? getTemplateById(String id) {
    try {
      return getAfrocentricTemplates().firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper method to create EventCreationData with proper initialization
  static EventCreationData _createEventData({
    required String name,
    required String description,
    required String category,
    required List<String> tags,
  }) {
    final data = EventCreationData();
    data.name = name;
    data.description = description;
    data.category = category;
    data.tags = tags;
    data.isFree = false; // Default to paid
    return data;
  }
}

class EventTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int color;
  final Duration suggestedDuration;
  final EventCreationData defaultData;

  const EventTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.suggestedDuration,
    required this.defaultData,
  });
}
