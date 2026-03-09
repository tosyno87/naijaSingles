import 'dart:async';
import 'dart:io';
import 'dart:math' show pi, sin;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/constants/app_colors.dart';
import '../../../common/utils/app_logger.dart';
import '../../../services/contact_invitation_service.dart';
import '../../../services/image_upload_service.dart';
import '../../../services/validation_service.dart';
import '../../../widgets/success_dialog.dart';
import '../../../widgets/tag_input_widget.dart';
import '../../groups/data/services/unified_group_service.dart';
import '../../groups/widgets/contact_picker_widget.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Services
  // ---------------------------------------------------------------------------
  final _groupService = UnifiedGroupService();
  final _imageService = ImageUploadService();
  final _imagePicker = ImagePicker();

  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  late final AnimationController _shakeController;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  int _currentStep = 0;
  GroupType _selectedType = _defaultType;
  final List<String> _selectedMembers = [];
  List<String> _tags = [];
  File? _selectedImage;
  bool _isCreating = false;
  bool _isPhotoPressed = false;
  int _nameCharCount = 0;
  int _descCharCount = 0;
  List<Map<String, dynamic>> _pendingInvitations = [];

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------
  static const _maxNameLength = 50;
  static const _maxDescLength = 500;
  static const _stepLabels = ['Basics', 'Audience', 'Extras'];
  static const _popularTypes = [
    GroupType.music,
    GroupType.sports,
    GroupType.travel,
    GroupType.food,
    GroupType.gaming,
    GroupType.career,
  ];
  static const _tagSuggestions = [
    'music',
    'nigerian',
    'afrobeats',
    'lagos',
    'abuja',
    'community',
    'friends',
    'networking',
    'events',
    'culture',
    'food',
    'travel',
    'sports',
    'fitness',
    'gaming',
    'art',
    'fashion',
    'tech',
    'business',
    'career',
    'study',
    'support',
    'local',
    'international',
  ];

  static const _defaultType = GroupType.music;

  bool get _isDirty =>
      _nameController.text.isNotEmpty ||
      _descriptionController.text.isNotEmpty ||
      _selectedImage != null ||
      _selectedMembers.isNotEmpty ||
      _tags.isNotEmpty ||
      _locationController.text.isNotEmpty ||
      _selectedType != _defaultType;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _nameController.addListener(_onNameChanged);
    _descriptionController.addListener(_onDescChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shakeController.dispose();
    _nameController
      ..removeListener(_onNameChanged)
      ..dispose();
    _descriptionController
      ..removeListener(_onDescChanged)
      ..dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_nameCharCount != _nameController.text.length) {
      setState(() => _nameCharCount = _nameController.text.length);
    }
  }

  void _onDescChanged() {
    if (_descCharCount != _descriptionController.text.length) {
      setState(() => _descCharCount = _descriptionController.text.length);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _currentStep == 0 && !_isDirty,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_currentStep > 0) {
            _previousStep();
          } else {
            unawaited(_onClose());
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundColor,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            leading: IconButton(
              icon: Icon(
                _currentStep > 0 ? Icons.arrow_back : Icons.close,
              ),
              onPressed: _currentStep > 0
                  ? _previousStep
                  : () => unawaited(_onClose()),
            ),
            title: Text(
              'Create Community',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentStep = page),
                  children: [
                    _buildBasicsStep(),
                    _buildAudienceStep(),
                    _buildExtrasStep(),
                  ],
                ),
              ),
              _buildStickyBottomBar(),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Progress bar
  // ---------------------------------------------------------------------------

  Widget _buildProgressBar() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primaryGreen),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (i) {
                final isActive = i == _currentStep;
                final isCompleted = i < _currentStep;
                return Text(
                  _stepLabels[i],
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive || isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                );
              }),
            ),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Sticky bottom CTA
  // ---------------------------------------------------------------------------

  Widget _buildStickyBottomBar() {
    final isLastStep = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF0AA36C)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCreating
                    ? null
                    : (isLastStep ? _createGroup : _nextStep),
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isCreating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLastStep ? 'Create Community' : 'Next',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1 — BASICS
  // ===========================================================================

  Widget _buildBasicsStep() => AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeOffset(_shakeController.value), 0),
          child: child,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoHero(),
                const SizedBox(height: 32),
                _buildNameField(),
                const SizedBox(height: 24),
                _buildDescriptionField(),
                const SizedBox(height: 32),
                _buildTypePicker(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Photo hero card (16:9)
  // ---------------------------------------------------------------------------

  Widget _buildPhotoHero() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cover Photo', helper: 'Optional'),
          const SizedBox(height: 12),
          GestureDetector(
            onTapDown: (_) => setState(() => _isPhotoPressed = true),
            onTapUp: (_) {
              setState(() => _isPhotoPressed = false);
              unawaited(_showImagePickerSheet());
            },
            onTapCancel: () => setState(() => _isPhotoPressed = false),
            child: AnimatedScale(
              scale: _isPhotoPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.surfaceColor,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImage != null
                      ? _buildPhotoFilled()
                      : _buildPhotoEmpty(),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildPhotoEmpty() => Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen.withValues(alpha: 0.06),
                  AppColors.primaryGreen.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: AppColors.primaryGreen.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 10),
              Text(
                'Add Cover Photo',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recommended: 16:9 ratio',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildPhotoFilled() => Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_outlined, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    'Change Photo',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Name field
  // ---------------------------------------------------------------------------

  Widget _buildNameField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxNameLength),
            ],
            decoration: _fieldDecoration(
              label: 'Community Name',
              helper: 'Choose a name that reflects your community',
              prefixIcon: Icons.group_outlined,
            ),
            style: _fieldTextStyle,
            validator: ValidationService.validateGroupName,
          ),
          const SizedBox(height: 6),
          _buildCharCounter(_nameCharCount, _maxNameLength),
        ],
      );

  // ---------------------------------------------------------------------------
  // Description field
  // ---------------------------------------------------------------------------

  Widget _buildDescriptionField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_maxDescLength),
            ],
            decoration: _fieldDecoration(
              label: 'Description',
              helper: 'What is this community about?',
              prefixIcon: Icons.notes_outlined,
            ),
            style: _fieldTextStyle,
            validator: ValidationService.validateGroupDescription,
          ),
          const SizedBox(height: 6),
          _buildCharCounter(_descCharCount, _maxDescLength),
        ],
      );

  // ---------------------------------------------------------------------------
  // Type picker — top 6 + "See all"
  // ---------------------------------------------------------------------------

  Widget _buildTypePicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Community Type',
            helper: 'Pick a category',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularTypes.map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  unawaited(HapticFeedback.lightImpact());
                  setState(() => _selectedType = type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getGroupTypeIcon(type),
                        size: 16,
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getGroupTypeLabel(type),
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (!_popularTypes.contains(_selectedType))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Chip(
                avatar: Icon(
                  _getGroupTypeIcon(_selectedType),
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  _getGroupTypeLabel(_selectedType),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primaryGreen,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _showAllTypesSheet,
              icon: const Icon(
                Icons.grid_view_outlined,
                size: 18,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                'See all types',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      );

  void _showAllTypesSheet() {
    var searchQuery = '';
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setSheetState) {
              final filtered = GroupType.values.where((t) {
                if (searchQuery.isEmpty) return true;
                return _getGroupTypeLabel(t)
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
              }).toList();

              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: TextField(
                      onChanged: (v) => setSheetState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search community types...',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final type = filtered[i];
                        final isSelected = _selectedType == type;
                        return ListTile(
                          leading: Icon(
                            _getGroupTypeIcon(type),
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            _getGroupTypeLabel(type),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primaryGreen,
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () {
                            setState(() => _selectedType = type);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 2 — AUDIENCE
  // ===========================================================================

  Widget _buildAudienceStep() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMembersSection(),
            const SizedBox(height: 16),
            _buildSocialProofHint('Public groups get 3x more joins'),
            const SizedBox(height: 32),
            _buildLocationField(),
            const SizedBox(height: 40),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  Widget _buildMembersSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Invite Members',
            helper: 'Optional — invite friends to join',
          ),
          const SizedBox(height: 12),
          if (_selectedMembers.isEmpty)
            _buildMembersEmpty()
          else
            _buildMembersFilled(),
        ],
      );

  Widget _buildMembersEmpty() => GestureDetector(
        onTap: _selectMembers,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.person_add_alt_1_outlined,
                size: 36,
                color: AppColors.primaryGreen.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Members from Contacts',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Invite friends via phone contacts or email',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildMembersFilled() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _selectedMembers.length; i++)
                Chip(
                  avatar: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      _selectedMembers[i].substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    _selectedMembers[i],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  backgroundColor:
                      AppColors.primaryGreen.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  deleteIconColor: AppColors.primaryGreen,
                  onDeleted: () => _removeMemberAt(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _selectMembers,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Add more',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Location field
  // ---------------------------------------------------------------------------

  Widget _buildLocationField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Location',
            helper: 'Optional — helps nearby users find you',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: _fieldDecoration(
              label: 'City, Country',
              prefixIcon: Icons.location_on_outlined,
            ),
            style: _fieldTextStyle,
          ),
        ],
      );

  // ===========================================================================
  // STEP 3 — EXTRAS
  // ===========================================================================

  Widget _buildExtrasStep() => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTagsSection(),
            const SizedBox(height: 32),
            _buildReviewCard(),
            const SizedBox(height: 40),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Tags
  // ---------------------------------------------------------------------------

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            'Tags (${_tags.length}/5)',
            helper: 'Help others discover your community',
          ),
          const SizedBox(height: 12),
          TagInputWidget(
            tags: _tags,
            onTagsChanged: (tags) => setState(() => _tags = tags),
            hintText: 'e.g., music, nigerian, afrobeats',
            suggestions: _tagSuggestions,
          ),
          if (_tags.length < 3) ...[
            const SizedBox(height: 12),
            _buildSocialProofHint(
              'Add 3+ tags to improve discovery by 40%',
            ),
          ],
        ],
      );

  // ---------------------------------------------------------------------------
  // Review card
  // ---------------------------------------------------------------------------

  Widget _buildReviewCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Preview'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryGreen.withValues(alpha: 0.10),
                                AppColors.primaryGreen.withValues(alpha: 0.20),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 28,
                              color:
                                  AppColors.primaryGreen.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        _nameController.text.isEmpty
                            ? 'Community Name'
                            : _nameController.text,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _nameController.text.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        _descriptionController.text.isEmpty
                            ? 'Description will appear here'
                            : _descriptionController.text,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Metadata row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _buildReviewChip(
                            _getGroupTypeIcon(_selectedType),
                            _getGroupTypeLabel(_selectedType),
                          ),
                          if (_selectedMembers.isNotEmpty)
                            _buildReviewChip(
                              Icons.people_outline,
                              '${_selectedMembers.length} invited',
                            ),
                          if (_tags.isNotEmpty)
                            _buildReviewChip(
                              Icons.sell_outlined,
                              '${_tags.length} tags',
                            ),
                          if (_locationController.text.trim().isNotEmpty)
                            _buildReviewChip(
                              Icons.location_on_outlined,
                              _locationController.text.trim(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildReviewChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  // ===========================================================================
  // SHARED UI HELPERS
  // ===========================================================================

  Widget _buildSectionTitle(String title, {String? helper}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      );

  Widget _buildSocialProofHint(String text) => Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppColors.primaryGreen.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      );

  Widget _buildCharCounter(int current, int max) {
    final ratio = current / max;
    Color color;
    if (ratio >= 1.0) {
      color = AppColors.error;
    } else if (ratio >= 0.8) {
      color = Colors.orange.shade700;
    } else {
      color = AppColors.textSecondary;
    }
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$current/$max',
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  TextStyle get _fieldTextStyle => GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  InputDecoration _fieldDecoration({
    required String label,
    String? helper,
    IconData? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryGreen,
        ),
        helperText: helper,
        helperStyle: GoogleFonts.montserrat(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        helperMaxLines: 2,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary)
            : null,
        filled: true,
        fillColor: AppColors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      );

  // ===========================================================================
  // ANIMATIONS
  // ===========================================================================

  double _shakeOffset(double v) => sin(v * pi * 6) * 6 * (1 - v);

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _nextStep() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) {
      unawaited(_shakeController.forward(from: 0));
      unawaited(HapticFeedback.mediumImpact());
      return;
    }
    if (_currentStep < 2) {
      unawaited(
        _pageController.animateToPage(
          _currentStep + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      unawaited(
        _pageController.animateToPage(
          _currentStep - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _onClose() async {
    if (!_isDirty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Discard changes?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'You have unsaved changes that will be lost.',
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Editing',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if ((discard ?? false) && mounted) {
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Image picker
  // ---------------------------------------------------------------------------

  Future<void> _showImagePickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, size: 22),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, size: 22),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    size: 22,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedImage = null);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } on Object catch (e) {
      AppLogger.error('Image pick failed', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  void _selectMembers() {
    unawaited(
      Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => ContactPickerWidget(
            groupName: _nameController.text.isNotEmpty
                ? _nameController.text
                : 'New Group',
            groupId: '__pending__',
            deferSending: true,
            onInvitationsSent: (invitations) {
              if (!mounted) return;
              setState(() {
                _pendingInvitations = invitations;
                _selectedMembers.clear();
                for (final inv in invitations) {
                  final name =
                      inv['contactName'] as String? ?? inv['email'] as String?;
                  if (name != null && name.isNotEmpty) {
                    _selectedMembers.add(name);
                  }
                }
              });
            },
          ),
        ),
      ),
    );
  }

  void _removeMemberAt(int index) {
    setState(() {
      if (index >= 0 && index < _selectedMembers.length) {
        _selectedMembers.removeAt(index);
      }
      if (index >= 0 && index < _pendingInvitations.length) {
        _pendingInvitations.removeAt(index);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Invitation helpers
  // ---------------------------------------------------------------------------

  Future<({int sent, int failed, List<String> failedNames})>
      _sendPendingInvitations({
    required String groupId,
    required String groupName,
  }) async {
    if (_pendingInvitations.isEmpty) {
      return (sent: 0, failed: 0, failedNames: <String>[]);
    }

    final contactService = ContactInvitationService();

    final futures = _pendingInvitations.map((inv) async {
      inv['groupId'] = groupId;
      inv['groupName'] = groupName;
      final message = inv['message'] as String? ?? '';
      final name =
          inv['contactName'] as String? ?? inv['email'] as String? ?? 'Unknown';

      bool ok;
      if (inv['invitationType'] == 'phone') {
        ok = await contactService.sendSMSInvitation(
          phoneNumber: inv['phone'] as String,
          message: message,
        );
      } else {
        ok = await contactService.sendEmailInvitation(
          email: inv['email'] as String,
          subject: 'Invitation to join $groupName',
          message: message,
        );
      }
      return (name: name, success: ok);
    });

    final results = await Future.wait(futures);

    final failedNames =
        results.where((r) => !r.success).map((r) => r.name).toList();
    final sentCount = results.length - failedNames.length;

    AppLogger.info(
      'Invitations for group $groupId: $sentCount sent, '
      '${failedNames.length} failed',
    );

    return (
      sent: sentCount,
      failed: failedNames.length,
      failedNames: failedNames,
    );
  }

  String _buildSuccessMessage({
    required String groupName,
    required ({int sent, int failed, List<String> failedNames}) inviteResult,
  }) {
    final base = 'Your group "$groupName" has been created successfully!';
    if (inviteResult.sent == 0 && inviteResult.failed == 0) return base;
    if (inviteResult.failed == 0) {
      return '$base\n${inviteResult.sent} invitation(s) sent.';
    }
    if (inviteResult.sent == 0) {
      return '$base\nAll ${inviteResult.failed} invitation(s) failed to send.';
    }
    final names = inviteResult.failedNames.join(', ');
    return '$base\n${inviteResult.sent} sent, '
        '${inviteResult.failed} failed ($names).';
  }

  // ---------------------------------------------------------------------------
  // Create group
  // ---------------------------------------------------------------------------

  Future<void> _createGroup() async {
    unawaited(LoadingDialog.show(context: context));

    setState(() => _isCreating = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null || uid.isEmpty) {
            throw Exception('You must be signed in to upload a cover photo.');
          }
          imageUrl = await _imageService.uploadCompressedImage(
            imageFile: _selectedImage!,
            path: 'users/$uid/group_avatars',
          );
        } on Object catch (e) {
          AppLogger.error('Image upload failed', error: e);

          if (!mounted) return;
          LoadingDialog.hide(context);

          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                'Image upload failed',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
              content: Text(
                'The cover photo could not be uploaded. '
                'Create the community without it?',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Continue without photo',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (proceed != true) {
            if (mounted) setState(() => _isCreating = false);
            return;
          }

          if (!mounted) return;
          unawaited(LoadingDialog.show(context: context));
        }
      }

      final location = _locationController.text.trim();

      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        location: location.isEmpty ? null : location,
        imageUrl: imageUrl,
        tags: _tags,
      );

      final inviteResult = await _sendPendingInvitations(
        groupId: group.id,
        groupName: _nameController.text.trim(),
      );

      if (!mounted) return;
      LoadingDialog.hide(context);

      if (mounted) {
        await SuccessDialog.show(
          context: context,
          title: 'Group Created!',
          message: _buildSuccessMessage(
            groupName: _nameController.text.trim(),
            inviteResult: inviteResult,
          ),
          actionText: 'Open Group',
          onAction: () {
            Navigator.pop(context);
            unawaited(
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupChatScreen(groupId: group.id),
                ),
              ),
            );
          },
          onClose: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    } on Object catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // ===========================================================================
  // GROUP TYPE HELPERS
  // ===========================================================================

  String _getGroupTypeLabel(GroupType type) {
    switch (type) {
      case GroupType.music:
        return 'Music';
      case GroupType.sports:
        return 'Sports';
      case GroupType.travel:
        return 'Travel';
      case GroupType.food:
        return 'Food';
      case GroupType.art:
        return 'Art';
      case GroupType.career:
        return 'Career';
      case GroupType.fitness:
        return 'Fitness';
      case GroupType.gaming:
        return 'Gaming';
      case GroupType.reading:
        return 'Reading';
      case GroupType.movies:
        return 'Movies';
      case GroupType.events:
        return 'Events';
      case GroupType.networking:
        return 'Networking';
      case GroupType.support:
        return 'Support';
      case GroupType.study:
        return 'Study';
      case GroupType.local:
        return 'Local';
      case GroupType.tech:
        return 'Technology';
      case GroupType.fashion:
        return 'Fashion';
      case GroupType.pets:
        return 'Pets';
      case GroupType.parenting:
        return 'Parenting';
      case GroupType.seniors:
        return 'Seniors';
    }
  }

  IconData _getGroupTypeIcon(GroupType type) {
    switch (type) {
      case GroupType.music:
        return Icons.music_note_outlined;
      case GroupType.sports:
        return Icons.sports_soccer_outlined;
      case GroupType.travel:
        return Icons.travel_explore_outlined;
      case GroupType.food:
        return Icons.restaurant_outlined;
      case GroupType.art:
        return Icons.palette_outlined;
      case GroupType.career:
        return Icons.work_outline;
      case GroupType.fitness:
        return Icons.fitness_center_outlined;
      case GroupType.gaming:
        return Icons.sports_esports_outlined;
      case GroupType.reading:
        return Icons.menu_book_outlined;
      case GroupType.movies:
        return Icons.movie_outlined;
      case GroupType.events:
        return Icons.event_outlined;
      case GroupType.networking:
        return Icons.people_outline;
      case GroupType.support:
        return Icons.support_agent_outlined;
      case GroupType.study:
        return Icons.school_outlined;
      case GroupType.local:
        return Icons.location_on_outlined;
      case GroupType.tech:
        return Icons.computer_outlined;
      case GroupType.fashion:
        return Icons.checkroom_outlined;
      case GroupType.pets:
        return Icons.pets_outlined;
      case GroupType.parenting:
        return Icons.child_care_outlined;
      case GroupType.seniors:
        return Icons.elderly_outlined;
    }
  }
}
