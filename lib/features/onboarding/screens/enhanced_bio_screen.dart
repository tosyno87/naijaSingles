import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../user/controllers/onboarding_controller.dart';

class EnhancedBioScreen extends StatefulWidget {
  const EnhancedBioScreen({super.key});

  @override
  State<EnhancedBioScreen> createState() => _EnhancedBioScreenState();
}

class _EnhancedBioScreenState extends State<EnhancedBioScreen> {
  final TextEditingController _bioController = TextEditingController();
  final int _maxLength = 300;
  final int _minLength = 50;
  final int _optimalMin = 50;
  final int _optimalMax = 200;
  
  int _currentLength = 0;
  String? _selectedPrompt;
  
  // Personality prompts for dating context
  final List<String> _personalityPrompts = [
    "I'm the type of person who...",
    "You'll find me on weekends...",
    "I'm passionate about...",
    "My friends would describe me as...",
    "I'm looking for someone who...",
    "My ideal date would be...",
    "I can't live without...",
    "Ask me about...",
    "Currently obsessed with...",
    "My hidden talent is...",
    "I believe in...",
    "Life's too short not to...",
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<OnboardingController>(context, listen: false);
      
      if (controller.bio.isNotEmpty) {
        _bioController.text = controller.bio;
        setState(() {
          _currentLength = controller.bio.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _selectPrompt(String prompt) {
    setState(() {
      if (_selectedPrompt == prompt) {
        // Deselect if same prompt is tapped
        _selectedPrompt = null;
        _bioController.clear();
        _currentLength = 0;
      } else {
        // Select new prompt and replace bio content
        _selectedPrompt = prompt;
        _bioController.text = '$prompt ';
        _currentLength = _bioController.text.length;
        
        // Move cursor to end
        _bioController.selection = TextSelection.fromPosition(
          TextPosition(offset: _bioController.text.length),
        );
      }
    });
    
    // Save to controller
    Provider.of<OnboardingController>(context, listen: false)
        .setBio(_bioController.text);
  }



  BioQuality _analyzeBioQuality() {
    String bio = _bioController.text.toLowerCase();
    
    bool hasOptimalLength = _currentLength >= _optimalMin && _currentLength <= _optimalMax;
    bool hasMinLength = _currentLength >= _minLength;
    bool hasPersonality = _hasPersonalityWords(bio);
    bool hasConversationStarter = _hasConversationStarter(bio);
    bool avoidsCliches = !_containsCliches(bio);
    
    int score = 0;
    if (hasMinLength) score += 20;
    if (hasOptimalLength) score += 20;
    if (hasPersonality) score += 25;
    if (hasConversationStarter) score += 25;
    if (avoidsCliches) score += 10;
    
    return BioQuality(
      score: score,
      hasOptimalLength: hasOptimalLength,
      hasMinLength: hasMinLength,
      hasPersonality: hasPersonality,
      hasConversationStarter: hasConversationStarter,
      avoidsCliches: avoidsCliches,
    );
  }

  bool _hasPersonalityWords(String bio) {
    List<String> personalityWords = [
      'love', 'enjoy', 'passionate', 'hobby', 'interest', 'like', 'favorite',
      'travel', 'music', 'food', 'adventure', 'creative', 'funny', 'kind',
      'active', 'outdoors', 'reading', 'cooking', 'dancing', 'sports'
    ];
    
    return personalityWords.any((word) => bio.contains(word));
  }

  bool _hasConversationStarter(String bio) {
    List<String> conversationStarters = [
      'ask me', 'tell me', 'what about', 'favorite', 'currently', 'obsessed',
      'challenge me', 'debate', 'recommend', 'share', 'discuss'
    ];
    
    return conversationStarters.any((starter) => bio.contains(starter)) ||
           bio.contains('?') || // Questions are great conversation starters
           _selectedPrompt != null;
  }

  bool _containsCliches(String bio) {
    List<String> cliches = [
      'love to laugh', 'work hard play hard', 'live laugh love', 'no drama',
      'just ask', 'good vibes only', 'fluent in sarcasm', 'netflix and chill'
    ];
    
    return cliches.any((cliche) => bio.contains(cliche));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF008037);
    const Color textColor = Color(0xFF333333);
    
    BioQuality quality = _analyzeBioQuality();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Tell your story",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            "Share what makes you unique and what you're looking for. A great bio helps you connect with the right people!",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bio Quality Indicator
          if (_currentLength > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBioQualityColor(quality.score).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBioQualityColor(quality.score),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getBioQualityIcon(quality.score),
                    color: _getBioQualityColor(quality.score),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getBioQualityMessage(quality.score),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getBioQualityColor(quality.score),
                          ),
                        ),
                        if (quality.score < 80) ...[
                          const SizedBox(height: 4),
                          Text(
                            _getBioImprovementTip(quality),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${quality.score}/100',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getBioQualityColor(quality.score),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Personality Prompts Section
          Text(
            "Get started with prompts",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  "Choose one prompt to get started",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  "Select 1",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Prompts Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _personalityPrompts.map((prompt) {
              bool isSelected = _selectedPrompt == prompt;
              
              return GestureDetector(
                onTap: () => _selectPrompt(prompt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        prompt,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: isSelected ? primaryColor : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Bio Text Field
          Text(
            "Your bio",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _bioController,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textColor,
                height: 1.5,
              ),
              maxLines: 8,
              maxLength: _maxLength,
              decoration: InputDecoration(
                hintText: "Write about yourself, your interests, and what you're looking for...",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
                counterText: "",
              ),
              onChanged: (value) {
                setState(() {
                  _currentLength = value.length;
                  
                  // Check if user manually cleared the text or removed the selected prompt
                  if (_selectedPrompt != null && !value.startsWith(_selectedPrompt!)) {
                    _selectedPrompt = null;
                  }
                });
                
                // Save to controller
                Provider.of<OnboardingController>(context, listen: false)
                    .setBio(value);
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Character Counter with Quality Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCharacterCountMessage(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _getCharacterCountColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "$_currentLength/$_maxLength",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _currentLength >= _minLength
                      ? primaryColor
                      : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Bio Tips
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Tips for a great bio",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                _buildTipItem(
                  "Be authentic and show your personality",
                  Icons.favorite_outline,
                ),
                _buildTipItem(
                  "Mention specific interests and hobbies",
                  Icons.sports_soccer_outlined,
                ),
                _buildTipItem(
                  "Add something that's easy to start a conversation about",
                  Icons.chat_bubble_outline,
                ),
                _buildTipItem(
                  "Share what you're looking for in a connection",
                  Icons.people_outline,
                ),
                _buildTipItem(
                  "Keep it positive and engaging",
                  Icons.sentiment_satisfied_alt_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.blue.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBioQualityColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getBioQualityIcon(int score) {
    if (score >= 80) return Icons.check_circle;
    if (score >= 60) return Icons.warning;
    return Icons.error;
  }

  String _getBioQualityMessage(int score) {
    if (score >= 80) return "Great bio! 🎉";
    if (score >= 60) return "Good start! 👍";
    return "Needs improvement 📝";
  }

  String _getBioImprovementTip(BioQuality quality) {
    if (!quality.hasMinLength) return "Add more details about yourself";
    if (!quality.hasPersonality) return "Share your interests and hobbies";
    if (!quality.hasConversationStarter) return "Add something people can ask you about";
    if (!quality.avoidsCliches) return "Try to be more specific and unique";
    if (!quality.hasOptimalLength) return "Aim for 50-200 characters for best results";
    return "You're doing great!";
  }

  String _getCharacterCountMessage() {
    if (_currentLength < _minLength) {
      return "Add ${_minLength - _currentLength} more characters";
    } else if (_currentLength <= _optimalMax) {
      return "Perfect length! 👌";
    } else {
      return "Consider shortening for better impact";
    }
  }

  Color _getCharacterCountColor() {
    if (_currentLength < _minLength) return Colors.red;
    if (_currentLength <= _optimalMax) return Colors.green;
    return Colors.orange;
  }
}

// Bio Quality Data Class
class BioQuality {
  final int score;
  final bool hasOptimalLength;
  final bool hasMinLength;
  final bool hasPersonality;
  final bool hasConversationStarter;
  final bool avoidsCliches;

  BioQuality({
    required this.score,
    required this.hasOptimalLength,
    required this.hasMinLength,
    required this.hasPersonality,
    required this.hasConversationStarter,
    required this.avoidsCliches,
  });
}
