import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

enum InterestCategory {
  lifestyle,
  entertainment,
  sports,
  food,
  culture,
  creative,
  social,
  travel
}

extension InterestCategoryExtension on InterestCategory {
  String get displayName {
    switch (this) {
      case InterestCategory.lifestyle:
        return 'Lifestyle';
      case InterestCategory.entertainment:
        return 'Entertainment';
      case InterestCategory.sports:
        return 'Sports & Fitness';
      case InterestCategory.food:
        return 'Food & Dining';
      case InterestCategory.culture:
        return 'Nigerian Culture';
      case InterestCategory.creative:
        return 'Creative Arts';
      case InterestCategory.social:
        return 'Social & Community';
      case InterestCategory.travel:
        return 'Travel & Adventure';
    }
  }

  IconData get icon {
    switch (this) {
      case InterestCategory.lifestyle:
        return Icons.self_improvement;
      case InterestCategory.entertainment:
        return Icons.movie;
      case InterestCategory.sports:
        return Icons.sports_soccer;
      case InterestCategory.food:
        return Icons.restaurant;
      case InterestCategory.culture:
        return Icons.flag;
      case InterestCategory.creative:
        return Icons.palette;
      case InterestCategory.social:
        return Icons.people;
      case InterestCategory.travel:
        return Icons.flight;
    }
  }

  Color get color {
    switch (this) {
      case InterestCategory.lifestyle:
        return Colors.purple;
      case InterestCategory.entertainment:
        return Colors.red;
      case InterestCategory.sports:
        return Colors.orange;
      case InterestCategory.food:
        return Colors.brown;
      case InterestCategory.culture:
        return Colors.green;
      case InterestCategory.creative:
        return Colors.pink;
      case InterestCategory.social:
        return Colors.blue;
      case InterestCategory.travel:
        return Colors.teal;
    }
  }
}

class EnhancedInterestsScreen extends StatefulWidget {
  const EnhancedInterestsScreen({super.key});

  @override
  State<EnhancedInterestsScreen> createState() => _EnhancedInterestsScreenState();
}

class _EnhancedInterestsScreenState extends State<EnhancedInterestsScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 2;
  
  List<InterestCategory> _selectedCategories = [];
  List<String> _selectedInterests = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Method to handle external navigation (called by main onboarding)
  bool canContinue() {
    if (_currentStep == 0) {
      return _selectedCategories.length >= 3;
    } else {
      return _selectedInterests.length >= 5;
    }
  }

  // Method to handle external continue action
  bool handleContinue() {
    if (_currentStep == 0) {
      if (_selectedCategories.length < 3) {
        _showCategoryRequirementSnackBar();
        return false;
      }
      _nextStep();
      return false; // Don't proceed to next onboarding step yet
    } else {
      if (_selectedInterests.length < 5) {
        _showInterestRequirementSnackBar();
        return false;
      }
      return true; // Ready to proceed to next onboarding step
    }
  }

  void _showCategoryRequirementSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Please select at least 3 categories for better matching",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  void _showInterestRequirementSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Please select at least 5 interests for better matching",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  // Categorized interests with expanded Nigerian context
  final Map<InterestCategory, List<InterestItem>> _categorizedInterests = {
    InterestCategory.lifestyle: [
      InterestItem('Fitness', isPopular: true),
      InterestItem('Yoga'),
      InterestItem('Meditation'),
      InterestItem('Fashion', isPopular: true),
      InterestItem('Photography', isConversationStarter: true),
      InterestItem('Reading', isConversationStarter: true),
      InterestItem('Writing'),
      InterestItem('Blogging'),
      InterestItem('Personal Development'),
      InterestItem('Wellness'),
    ],
    
    InterestCategory.entertainment: [
      InterestItem('Movies', isPopular: true, isConversationStarter: true),
      InterestItem('Music', isPopular: true, isConversationStarter: true),
      InterestItem('Concerts', isConversationStarter: true),
      InterestItem('Theatre'),
      InterestItem('Comedy Shows', isConversationStarter: true),
      InterestItem('Netflix', isPopular: true),
      InterestItem('Podcasts', isConversationStarter: true),
      InterestItem('Gaming', isConversationStarter: true),
      InterestItem('Karaoke', isConversationStarter: true),
      InterestItem('Live Music'),
    ],
    
    InterestCategory.sports: [
      InterestItem('Football', isPopular: true),
      InterestItem('Basketball'),
      InterestItem('Tennis'),
      InterestItem('Swimming'),
      InterestItem('Running', isPopular: true),
      InterestItem('Cycling'),
      InterestItem('Volleyball'),
      InterestItem('Martial Arts'),
      InterestItem('Boxing'),
      InterestItem('Table Tennis'),
    ],
    
    InterestCategory.food: [
      InterestItem('Cooking', isPopular: true, isConversationStarter: true),
      InterestItem('Fine Dining', isConversationStarter: true),
      InterestItem('Street Food', isPopular: true),
      InterestItem('Baking'),
      InterestItem('Wine Tasting'),
      InterestItem('Craft Beer'),
      InterestItem('Coffee', isPopular: true),
      InterestItem('Brunch', isConversationStarter: true),
      InterestItem('Food Photography'),
      InterestItem('Restaurant Reviews'),
    ],
    
    InterestCategory.culture: [
      // Expanded Nigerian cultural interests
      InterestItem('Afrobeats', isPopular: true, isConversationStarter: true),
      InterestItem('Highlife Music'),
      InterestItem('Fuji Music'),
      InterestItem('Juju Music'),
      InterestItem('Nollywood', isPopular: true, isConversationStarter: true),
      InterestItem('Jollof Rice', isPopular: true, isConversationStarter: true),
      InterestItem('Suya', isPopular: true),
      InterestItem('Pepper Soup'),
      InterestItem('Amala & Ewedu'),
      InterestItem('Pounded Yam'),
      InterestItem('Owanbe Parties', isPopular: true, isConversationStarter: true),
      InterestItem('Traditional Weddings', isConversationStarter: true),
      InterestItem('Cultural Festivals'),
      InterestItem('Ankara Fashion', isPopular: true),
      InterestItem('Gele Tying'),
      InterestItem('Traditional Attire'),
      InterestItem('Nigerian Designers'),
      InterestItem('Pidgin English', isConversationStarter: true),
      InterestItem('Yoruba Language'),
      InterestItem('Igbo Language'),
      InterestItem('Hausa Language'),
      InterestItem('Local Markets'),
      InterestItem('Nigerian Literature'),
      InterestItem('Cultural Dance'),
      InterestItem('Traditional Music'),
      InterestItem('Nigerian Comedy', isConversationStarter: true),
    ],
    
    InterestCategory.creative: [
      InterestItem('Painting'),
      InterestItem('Drawing'),
      InterestItem('Singing', isConversationStarter: true),
      InterestItem('Dancing', isPopular: true, isConversationStarter: true),
      InterestItem('Music Production'),
      InterestItem('DJ Culture'),
      InterestItem('Fashion Design'),
      InterestItem('Jewelry Making'),
      InterestItem('Crafts'),
      InterestItem('Interior Design'),
    ],
    
    InterestCategory.social: [
      InterestItem('Church Activities', isPopular: true),
      InterestItem('Mosque Activities'),
      InterestItem('Community Service'),
      InterestItem('Family Time', isPopular: true),
      InterestItem('Volunteering'),
      InterestItem('Youth Mentoring'),
      InterestItem('Social Activism'),
      InterestItem('Neighborhood Events'),
      InterestItem('Charity Work'),
      InterestItem('Religious Studies'),
    ],
    
    InterestCategory.travel: [
      InterestItem('Travel', isPopular: true, isConversationStarter: true),
      InterestItem('Hiking', isConversationStarter: true),
      InterestItem('Beach Activities', isPopular: true),
      InterestItem('Road Trips', isConversationStarter: true),
      InterestItem('Adventure Sports'),
      InterestItem('Camping'),
      InterestItem('City Exploration'),
      InterestItem('Cultural Tourism'),
      InterestItem('Food Tourism'),
      InterestItem('Photography Tours'),
    ],
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
      if (controller.interests.isNotEmpty) {
        setState(() {
          _selectedInterests = List.from(controller.interests);
          // Auto-select categories based on existing interests
          _autoSelectCategories();
        });
      }
    });
  }

  void _autoSelectCategories() {
    Set<InterestCategory> categories = {};
    
    for (String interest in _selectedInterests) {
      for (var entry in _categorizedInterests.entries) {
        if (entry.value.any((item) => item.name == interest)) {
          categories.add(entry.key);
        }
      }
    }
    
    _selectedCategories = categories.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _toggleCategory(InterestCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        // Remove all interests from this category
        List<String> categoryInterests = _categorizedInterests[category]!
            .map((item) => item.name)
            .toList();
        _selectedInterests.removeWhere((interest) => categoryInterests.contains(interest));
      } else {
        if (_selectedCategories.length < 6) {
          _selectedCategories.add(category);
        } else {
          _showMaxCategoriesSnackBar();
        }
      }
    });
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
        Provider.of<OnboardingController>(context, listen: false)
            .removeInterest(interest);
      } else {
        if (_selectedInterests.length < 15) {
          _selectedInterests.add(interest);
          Provider.of<OnboardingController>(context, listen: false)
              .addInterest(interest);
        } else {
          _showMaxInterestsSnackBar();
        }
      }
    });
  }

  void _showMaxCategoriesSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "You can select up to 6 categories for better matching",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange.shade400,
      ),
    );
  }

  void _showMaxInterestsSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "You can select up to 15 interests to keep your profile focused",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.orange.shade400,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<InterestItem> get _filteredInterests {
    List<InterestItem> allInterests = [];
    
    for (InterestCategory category in _selectedCategories) {
      allInterests.addAll(_categorizedInterests[category] ?? []);
    }
    
    if (_searchQuery.isEmpty) {
      return allInterests;
    }
    
    return allInterests.where((item) => 
      item.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF008037);
    const Color textColor = Color(0xFF333333);

    return Column(
      children: [
        // Header with progress
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: List.generate(_totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentStep ? primaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _currentStep == 0 ? "Choose Your Vibe" : "Select Your Interests",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _currentStep == 0 
                    ? "Pick 3-6 categories that match your lifestyle and personality"
                    : "Select specific interests from your chosen categories (up to 15)",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        // Page content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            children: [
              _buildCategorySelectionPage(),
              _buildInterestSelectionPage(),
            ],
          ),
        ),
        
        // Internal navigation for category to interests transition
        if (_currentStep == 0 && _selectedCategories.length >= 3)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Next: Select Interests',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategorySelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              "${_selectedCategories.length}/6 categories selected",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0, // Changed from 1.2 to 1.0 for more height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: InterestCategory.values.length,
            itemBuilder: (context, index) {
              final category = InterestCategory.values[index];
              final isSelected = _selectedCategories.contains(category);
              final interestCount = _categorizedInterests[category]?.length ?? 0;
              
              return GestureDetector(
                onTap: () => _toggleCategory(category),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? category.color.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? category.color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: category.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 28,
                          color: isSelected ? category.color : Colors.grey.shade600,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Flexible(
                          child: Text(
                            category.displayName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? category.color : Colors.black87,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        Text(
                          '$interestCount options',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: category.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Tips section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Why categories matter",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  "Selecting diverse categories helps us find people who share your lifestyle and values. The more categories you choose, the better we can match you with compatible people!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestSelectionPage() {
    return Column(
      children: [
        // Search and count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Search box
              TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Search interests",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Selection count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      "${_selectedInterests.length}/15 interests selected",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  
                  Text(
                    "Minimum 5 required",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Interests grid
        Expanded(
          child: _filteredInterests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No interests found",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try a different search term",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredInterests.length,
                  itemBuilder: (context, index) {
                    final interestItem = _filteredInterests[index];
                    final isSelected = _selectedInterests.contains(interestItem.name);
                    
                    return GestureDetector(
                      onTap: () => _toggleInterest(interestItem.name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF008037) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF008037)
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF008037).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Text(
                                    interestItem.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Badges
                              if (interestItem.isPopular || interestItem.isConversationStarter)
                                Flexible(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (interestItem.isPopular)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '🔥',
                                            style: TextStyle(fontSize: 8),
                                          ),
                                        ),
                                      
                                      if (interestItem.isPopular && interestItem.isConversationStarter)
                                        const SizedBox(width: 2),
                                    
                                    if (interestItem.isConversationStarter)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '💬',
                                          style: TextStyle(fontSize: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class InterestItem {
  final String name;
  final bool isPopular;
  final bool isConversationStarter;

  InterestItem(
    this.name, {
    this.isPopular = false,
    this.isConversationStarter = false,
  });
}
