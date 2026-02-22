import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/constants/app_colors.dart';
import '../../../data/models/enhanced_event_model.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({
    required this.eventData,
    super.key,
  });
  final EventCreationData eventData;

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;

  // Validation states
  bool _isNameValid = true;
  bool _isDescriptionValid = true;
  String? _nameError;
  String? _descriptionError;

  final List<String> _categories = [
    'Cultural Events',
    'Professional Networking',
    'Social Gatherings',
    'Lifestyle & Wellness',
    'Entertainment',
    'Sports & Fitness',
    'Food & Dining',
    'Arts & Crafts',
    'Technology',
    'Education',
    'Business',
    'Music',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.eventData.name);
    _descriptionController =
        TextEditingController(text: widget.eventData.description);
    _tagController = TextEditingController();

    _nameController.addListener(() {
      widget.eventData.name = _nameController.text;
      _validateName();
    });

    _descriptionController.addListener(() {
      widget.eventData.description = _descriptionController.text;
      _validateDescription();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _isNameValid = false;
        _nameError = 'Event name is required';
      } else if (name.length < 3) {
        _isNameValid = false;
        _nameError = 'Event name must be at least 3 characters';
      } else if (name.length > 100) {
        _isNameValid = false;
        _nameError = 'Event name must be less than 100 characters';
      } else {
        _isNameValid = true;
        _nameError = null;
      }
    });
  }

  void _validateDescription() {
    final description = _descriptionController.text.trim();
    setState(() {
      if (description.isEmpty) {
        _isDescriptionValid = false;
        _descriptionError = 'Event description is required';
      } else if (description.length < 10) {
        _isDescriptionValid = false;
        _descriptionError = 'Event description must be at least 10 characters';
      } else if (description.length > 2000) {
        _isDescriptionValid = false;
        _descriptionError =
            'Event description must be less than 2000 characters';
      } else {
        _isDescriptionValid = true;
        _descriptionError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Event Details'),
            const SizedBox(height: 20),
            _buildEventNameField(),
            const SizedBox(height: 20),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildCategorySelector(),
            const SizedBox(height: 20),
            _buildTagsSection(),
            const SizedBox(height: 40),
          ],
        ),
      );

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF333333),
        ),
      );

  Widget _buildEventNameField() {
    final currentLength = _nameController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Event Name *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isNameValid
                    ? const Color(0xFF008037).withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isNameValid ? const Color(0xFF008037) : Colors.red,
                ),
              ),
              child: Text(
                '$currentLength/100',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isNameValid ? const Color(0xFF008037) : Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          maxLength: 100,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            hintText:
                'e.g., "Lagos Singles Mixer Night" or "Tech Networking Brunch"',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isNameValid
                    ? const Color(0xFF008037).withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isNameValid
                    ? const Color(0xFF008037).withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isNameValid ? const Color(0xFF008037) : Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withValues(alpha: 0.7),
            ),
          ),
        ),
        if (_nameError != null) ...[
          const SizedBox(height: 4),
          Text(
            _nameError!,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField() {
    final currentLength = _descriptionController.text.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Event Description *',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isDescriptionValid
                    ? const Color(0xFF008037).withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDescriptionValid
                      ? const Color(0xFF008037)
                      : Colors.red,
                ),
              ),
              child: Text(
                '$currentLength/2000',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _isDescriptionValid
                      ? const Color(0xFF008037)
                      : Colors.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 6,
          maxLength: 2000,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF333333),
          ),
          decoration: InputDecoration(
            hintText:
                'Describe your event in detail. What can attendees expect?\n\nExample: Join us for an exciting evening of networking and fun! We\'ll have great music, delicious food, and opportunities to meet amazing people.',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isDescriptionValid
                    ? const Color(0xFF008037).withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isDescriptionValid
                    ? const Color(0xFF008037).withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    _isDescriptionValid ? const Color(0xFF008037) : Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withValues(alpha: 0.7),
            ),
          ),
        ),
        if (_descriptionError != null) ...[
          const SizedBox(height: 4),
          Text(
            _descriptionError!,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Category *',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor, // Afropeep cream background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF008037)
                    .withValues(alpha: 0.3), // Afropeep green border
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.eventData.category.isEmpty
                    ? null
                    : widget.eventData.category,
                hint: Text(
                  'Select a category',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF008037)
                        .withValues(alpha: 0.7), // Afropeep green hint
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF008037), // Afropeep green icon
                  size: 24,
                ),
                isExpanded: true,
                dropdownColor:
                    AppColors.backgroundColor, // Afropeep cream dropdown
                items: _categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            category,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: const Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    widget.eventData.category = value ?? '';
                  });
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags (Optional)',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add tags to help people discover your event',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),

          // Tag input field
          Row(
            children: [
              Flexible(
                flex: 3,
                child: TextFormField(
                  controller: _tagController,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: const Color(0xFF333333),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter a tag',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: const Color(0xFF008037)
                          .withValues(alpha: 0.7), // Afropeep green hint
                    ),
                    filled: true,
                    fillColor: AppColors
                        .backgroundColor, // Afropeep cream background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF008037)
                            .withValues(alpha: 0.3), // Afropeep green border
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: const Color(0xFF008037)
                            .withValues(alpha: 0.3), // Afropeep green border
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF008037), width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onFieldSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton(
                  onPressed: () => _addTag(_tagController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008037),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(50, 48), // Smaller minimum size
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Display tags
          if (widget.eventData.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.eventData.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF008037).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF008037).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: const Color(0xFF008037),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeTag(tag),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Color(0xFF008037),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),

          if (widget.eventData.tags.length >= 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Maximum 10 tags allowed',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty &&
        !widget.eventData.tags.contains(trimmedTag) &&
        widget.eventData.tags.length < 10) {
      setState(() {
        widget.eventData.tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      widget.eventData.tags.remove(tag);
    });
  }
}
