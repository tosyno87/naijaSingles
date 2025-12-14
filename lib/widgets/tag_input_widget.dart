import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/constants/app_colors.dart';
import '../services/validation_service.dart';

/// Widget for inputting and managing tags
class TagInputWidget extends StatefulWidget {

  const TagInputWidget({
    required this.tags, required this.onTagsChanged, super.key,
    this.maxTags = 5,
    this.hintText = 'Add tags...',
    this.suggestions = const [],
  });
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final int maxTags;
  final String hintText;
  final List<String> suggestions;

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestions;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags display
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map(_buildTagChip).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Tag input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: GoogleFonts.montserrat(
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              onPressed: _addTag,
              icon: const Icon(
                Icons.add,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          style: GoogleFonts.montserrat(),
          onChanged: _onTextChanged,
          onSubmitted: (_) => _addTag(),
        ),

        // Suggestions
        if (_filteredSuggestions.isNotEmpty && _controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return ListTile(
                  title: Text(
                    suggestion,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                    ),
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        ],

        // Tag limit indicator
        if (widget.tags.length >= widget.maxTags) ...[
          const SizedBox(height: 8),
          Text(
            'Maximum ${widget.maxTags} tags allowed',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.orange[600],
            ),
          ),
        ],
      ],
    );

  Widget _buildTagChip(String tag) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );

  void _onTextChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredSuggestions = widget.suggestions;
      } else {
        _filteredSuggestions = widget.suggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(value.toLowerCase()) &&
                !widget.tags.contains(suggestion),)
            .toList();
      }
    });
  }

  void _addTag() {
    final String tag = _controller.text.trim();

    if (tag.isEmpty) return;

    // Validate tag
    final String? validationError = ValidationService.validateTag(tag);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if tag already exists
    if (widget.tags.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "$tag" already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check tag limit
    if (widget.tags.length >= widget.maxTags) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxTags} tags allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add tag
    final List<String> newTags = [...widget.tags, tag];
    widget.onTagsChanged(newTags);
    _controller.clear();
    _focusNode.unfocus();
  }

  void _removeTag(String tag) {
    final List<String> newTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(newTags);
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _addTag();
  }
}
