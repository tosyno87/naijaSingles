import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/enhanced_event_model.dart';

class BasicInfoStep extends StatefulWidget {
  final EventCreationData eventData;

  const BasicInfoStep({
    Key? key,
    required this.eventData,
  }) : super(key: key);

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;

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
    _descriptionController = TextEditingController(text: widget.eventData.description);
    _tagController = TextEditingController();

    _nameController.addListener(() {
      widget.eventData.name = _nameController.text;
      setState(() {}); // Update UI for validation indicators
    });

    _descriptionController.addListener(() {
      widget.eventData.description = _descriptionController.text;
      setState(() {}); // Update UI for validation indicators
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildEventNameField() {
    final currentLength = _nameController.text.length;
    final isValid = currentLength >= 3;
    
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
                color: isValid ? const Color(0xFF008037).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValid ? const Color(0xFF008037) : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                'Min 3 chars',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isValid ? const Color(0xFF008037) : Colors.orange,
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
            hintText: 'e.g., "Lagos Singles Mixer Night" or "Tech Networking Brunch"',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withOpacity(0.6),
            ),
            filled: true,
            fillColor: const Color(0xFFFFF6E5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037).withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037).withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037) : Colors.orange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withOpacity(0.7),
            ),
          ),
        ),
        if (!isValid && currentLength > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${3 - currentLength} more characters needed',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionField() {
    final currentLength = _descriptionController.text.length;
    final isValid = currentLength >= 10;
    
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
                color: isValid ? const Color(0xFF008037).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isValid ? const Color(0xFF008037) : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                'Min 10 chars',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isValid ? const Color(0xFF008037) : Colors.orange,
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
            hintText: 'Describe your event in detail. What can attendees expect?\n\nExample: Join us for an exciting evening of networking and fun! We\'ll have great music, delicious food, and opportunities to meet amazing people.',
            hintStyle: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF008037).withOpacity(0.6),
            ),
            filled: true,
            fillColor: const Color(0xFFFFF6E5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037).withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037).withOpacity(0.3) : Colors.orange.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isValid ? const Color(0xFF008037) : Colors.orange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterStyle: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF008037).withOpacity(0.7),
            ),
          ),
        ),
        if (!isValid && currentLength > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${10 - currentLength} more characters needed',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
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
            color: const Color(0xFFFFF6E5), // NaijaSingles cream background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF008037).withOpacity(0.3), // NaijaSingles green border
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.eventData.category.isEmpty ? null : widget.eventData.category,
              hint: Text(
                'Select a category',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF008037).withOpacity(0.7), // NaijaSingles green hint
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
                color: Color(0xFF008037), // NaijaSingles green icon
                size: 24,
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFFFFF6E5), // NaijaSingles cream dropdown
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
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
                );
              }).toList(),
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
  }

  Widget _buildTagsSection() {
    return Column(
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
                    color: const Color(0xFF008037).withOpacity(0.7), // NaijaSingles green hint
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF6E5), // NaijaSingles cream background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF008037).withOpacity(0.3), // NaijaSingles green border
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF008037).withOpacity(0.3), // NaijaSingles green border
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF008037), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 1,
              child: ElevatedButton(
                onPressed: () => _addTag(_tagController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            children: widget.eventData.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF008037).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF008037).withOpacity(0.3),
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
              );
            }).toList(),
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
  }

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
