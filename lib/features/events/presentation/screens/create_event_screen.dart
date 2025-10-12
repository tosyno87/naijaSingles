import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/routes/route_name.dart';
import '../bloc/event_creation_bloc.dart';
import '../widgets/create_event_steps/basic_info_step.dart';
import '../widgets/create_event_steps/cultural_heritage_step.dart';
import '../widgets/create_event_steps/datetime_step.dart';
import '../widgets/create_event_steps/location_step.dart';
import '../widgets/create_event_steps/advanced_settings_step.dart';
import '../widgets/create_event_steps/preview_step.dart';
import '../../data/models/enhanced_event_model.dart';
import '../../data/services/event_templates_service.dart';

class CreateEventScreen extends StatefulWidget {
  final EnhancedEventModel? existingEvent; // For editing existing events
  final EventTemplate? template; // For template-based creation

  const CreateEventScreen({
    Key? key,
    this.existingEvent,
    this.template,
  }) : super(key: key);

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  late EventCreationData _eventData;
  bool _isEditing = false;
  bool _isSubmitting = false; // Add local loading state
  Timer? _debounceTimer; // Add debounce timer
  Timer? _autoSaveTimer; // Add auto-save timer
  bool _hasUnsavedChanges = false; // Track unsaved changes

  final List<String> _stepTitles = [
    'Basic Info',
    'Cultural Heritage',
    'Date & Time',
    'Location',
    'Advanced Settings',
    'Preview',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingEvent != null;
    _initializeEventData();
    _startAutoSave();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _initializeEventData() {
    if (_isEditing && widget.existingEvent != null) {
      final event = widget.existingEvent!;
      _eventData = EventCreationData()
        ..name = event.name
        ..description = event.description
        ..startDate = event.startDate
        ..endDate = event.endDate
        ..location = event.location
        ..imageUrls = List.from(event.imageUrls)
        ..isFree = event.isFree
        ..ticketPrice = event.ticketPrice
        ..category = event.category
        ..tags = List.from(event.tags)
        ..maxAttendees = event.maxAttendees
        ..metadata = Map.from(event.metadata);
    } else if (widget.template != null) {
      // Initialize with template data
      final template = widget.template!;
      final templateData = template.defaultData;
      final now = DateTime.now();

      _eventData = EventCreationData()
        ..name = templateData.name
        ..description = templateData.description
        ..category = templateData.category
        ..tags = List.from(templateData.tags)
        ..startDate = now.add(const Duration(days: 7)) // Default to next week
        ..endDate =
            now.add(const Duration(days: 7)).add(template.suggestedDuration)
        ..isFree = templateData.isFree
        ..ticketPrice = templateData.ticketPrice
        ..maxAttendees = templateData.maxAttendees;
    } else {
      _eventData = EventCreationData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: BlocListener<EventCreationBloc, EventCreationState>(
        listener: _handleBlocState,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  BasicInfoStep(eventData: _eventData),
                  CulturalHeritageStep(eventData: _eventData),
                  DateTimeStep(eventData: _eventData),
                  LocationStep(eventData: _eventData),
                  AdvancedSettingsStep(eventData: _eventData),
                  PreviewStep(eventData: _eventData),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Color(0xFF333333)),
        onPressed: _handleBackPress,
      ),
      title: Row(
        children: [
          Text(
            _isEditing ? 'Edit Event' : 'Create Event',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          if (_hasUnsavedChanges) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_currentStep < _stepTitles.length - 1) // Don't show on preview step
          TextButton(
            onPressed: _saveAsDraft,
            child: Text(
              'Save Draft',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF008037),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                      right: index < _stepTitles.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? const Color(0xFF008037)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '${_currentStep + 1} of ${_stepTitles.length}: ${_stepTitles[_currentStep]}',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF008037)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF008037),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<EventCreationBloc, EventCreationState>(
              builder: (context, state) {
                final isLoading = state is EventCreationLoading;
                final isDisabled = isLoading || _isSubmitting;

                return ElevatedButton(
                  onPressed: isDisabled ? null : _handleNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008037),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isDisabled
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          _getNextButtonText(),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    if (_currentStep == _stepTitles.length - 1) {
      return _isEditing ? 'Update Event' : 'Create Event';
    }
    return 'Next';
  }

  void _handleNextStep() {
    // Prevent multiple rapid calls
    if (_isSubmitting) return;

    if (_currentStep < _stepTitles.length - 1) {
      _nextStep();
    } else {
      _submitEvent();
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _validateBasicInfo();
      case 1: // Cultural Heritage
        return _validateCulturalHeritage();
      case 2: // Date & Time
        return _validateDateTime();
      case 3: // Location
        return _validateLocation();
      case 4: // Advanced Settings
        return _validateAdvancedSettings();
      case 5: // Preview
        return true;
      default:
        return true;
    }
  }

  bool _validateBasicInfo() {
    if (_eventData.name.trim().isEmpty) {
      _showError('Please enter an event name');
      return false;
    }
    if (_eventData.description.trim().isEmpty) {
      _showError('Please enter an event description');
      return false;
    }
    if (_eventData.category.trim().isEmpty) {
      _showError('Please select an event category');
      return false;
    }
    return true;
  }

  bool _validateCulturalHeritage() {
    if (_eventData.metadata['culturalHeritage'] == null ||
        _eventData.metadata['culturalHeritage'].toString().trim().isEmpty) {
      _showError('Please select a cultural heritage');
      return false;
    }
    if (_eventData.metadata['ageGroup'] == null ||
        _eventData.metadata['ageGroup'].toString().trim().isEmpty) {
      _showError('Please select a target age group');
      return false;
    }
    return true;
  }

  bool _validateDateTime() {
    if (_eventData.startDate == null) {
      _showError('Please select a start date and time');
      return false;
    }
    if (_eventData.endDate == null) {
      _showError('Please select an end date and time');
      return false;
    }
    if (_eventData.startDate!
        .isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      _showError('Event must start at least 1 hour from now');
      return false;
    }
    if (_eventData.endDate!.isBefore(_eventData.startDate!)) {
      _showError('End date must be after start date');
      return false;
    }
    return true;
  }

  bool _validateLocation() {
    if (_eventData.location == null) {
      _showError('Please select an event location');
      return false;
    }
    return true;
  }

  bool _validateAdvancedSettings() {
    // Advanced settings are optional, but validate if user has made changes
    if (!_eventData.isFree &&
        (_eventData.ticketPrice == null || _eventData.ticketPrice! <= 0)) {
      _showError('Please enter a valid ticket price for paid events');
      return false;
    }
    if (_eventData.maxAttendees <= 0) {
      _showError('Please enter a valid maximum number of attendees');
      return false;
    }
    return true;
  }

  void _submitEvent() {
    // Prevent multiple submissions
    if (_isSubmitting) return;

    // Cancel any existing timer
    _debounceTimer?.cancel();

    setState(() {
      _isSubmitting = true;
    });

    // Add a small delay to prevent rapid successive calls
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      final bloc = context.read<EventCreationBloc>();

      if (_isEditing) {
        bloc.add(UpdateEventEvent(widget.existingEvent!.id, _eventData));
      } else {
        bloc.add(CreateEventEvent(_eventData));
      }
    });
  }

  void _startAutoSave() {
    // Auto-save every 30 seconds if there are unsaved changes
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_hasUnsavedChanges && !_isSubmitting) {
        _autoSaveDraft();
      }
    });
  }

  void _autoSaveDraft() {
    // Only auto-save if we have some basic data
    if (_eventData.name.isNotEmpty || _eventData.description.isNotEmpty) {
      final bloc = context.read<EventCreationBloc>();
      bloc.add(SaveEventAsDraftEvent(_eventData));
      _hasUnsavedChanges = false;
    }
  }

  void _saveAsDraft() {
    final bloc = context.read<EventCreationBloc>();
    bloc.add(SaveEventAsDraftEvent(_eventData));
    _hasUnsavedChanges = false;
  }

  void _handleBlocState(BuildContext context, EventCreationState state) {
    // Reset submitting state on completion
    if (state is EventCreationSuccess || state is EventCreationError) {
      setState(() {
        _isSubmitting = false;
      });
    }

    if (state is EventCreationSuccess) {
      _showSuccessDialog(state.message, state.eventId);
    } else if (state is EventCreationError) {
      _showError(state.message);
    } else if (state is EventDraftSaved) {
      _showSuccessDialog('Event saved as draft successfully!');
    }
  }

  void _showSuccessDialog(String message, [String? eventId]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54, // Fix dark screen issue
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Ensure white background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF008037), size: 28),
            const SizedBox(width: 12),
            Expanded(
              // Prevent text overflow
              child: Text(
                'Success!',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            color: const Color(0xFF666666),
          ),
        ),
        actions: [
          if (eventId != null) ...[
            // Button row with proper spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Close button
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Close create event screen
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // View My Events button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      print('[DEBUG] View My Events button pressed');
                      // Close the dialog first
                      Navigator.of(context).pop();
                      print('[DEBUG] Dialog closed, navigating to My Events');

                      // Navigate to My Events page
                      _navigateToMyEvents();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008037),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View My Events',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close create event screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008037),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToMyEvents() async {
    print('[DEBUG] _navigateToMyEvents called');

    // Get context references before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      print('[DEBUG] Attempting to navigate to My Events screen');
      // Replace the current create event screen with My Events screen
      // This ensures back button goes to the screen before create event
      await navigator.pushReplacementNamed(RouteName.myEvents);
      print('[DEBUG] Navigation to My Events successful');
    } catch (e) {
      print('[DEBUG] Navigation failed: $e, using fallback');
      // Fallback navigation - go back to main navigation
      navigator.pushNamedAndRemoveUntil(
        RouteName.mainNavigation,
        (route) => false,
      );
    }

    // Show success message after navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        print('[DEBUG] Showing success snackbar');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Event created successfully! Check the Events tab to view your event.',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF008037),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleBackPress() {
    if (_hasUnsavedChanges) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Discard Changes?',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. Do you want to save as draft or discard them?',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF666666),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Discard',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _saveAsDraft();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008037),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save Draft',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}
