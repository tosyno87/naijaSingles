import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/rsvp_model.dart';
import '../bloc/rsvp_bloc.dart';
import '../../../../common/constants/app_colors.dart';

class RSVPButton extends StatefulWidget {
  const RSVPButton({
    required this.eventId,
    super.key,
    this.compact = false,
    this.initialStatus,
  });
  final String eventId;
  final bool compact;
  final RSVPStatus? initialStatus;

  @override
  State<RSVPButton> createState() => _RSVPButtonState();
}

class _RSVPButtonState extends State<RSVPButton>
    with SingleTickerProviderStateMixin {
  RSVPStatus _currentStatus = RSVPStatus.none;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus ?? RSVPStatus.none;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Load current RSVP status
    _loadRSVPStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadRSVPStatus() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<RSVPBloc>().add(
          LoadEventRSVPStatusEvent(
            userId: currentUserId,
            eventId: widget.eventId,
          ),
        );
  }

  void _handleRSVPTap() {
    if (_isLoading) return;

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (_currentStatus == RSVPStatus.going) {
      _showRSVPOptions();
    } else {
      _updateRSVP(RSVPStatus.going);
    }
  }

  void _updateRSVP(RSVPStatus newStatus) {
    setState(() {
      _isLoading = true;
    });

    context.read<RSVPBloc>().add(
          RSVPToEventEvent(
            eventId: widget.eventId,
            status: newStatus,
          ),
        );
  }

  void _showRSVPOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRSVPOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<RSVPBloc, RSVPState>(
        listener: (context, state) {
          if (state is RSVPSuccess && state.eventId == widget.eventId) {
            setState(() {
              _currentStatus = state.status;
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
                backgroundColor: AppColors.primaryGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is RSVPError && state.eventId == widget.eventId) {
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          } else if (state is EventRSVPStatusLoaded &&
              state.eventId == widget.eventId) {
            setState(() {
              _currentStatus = state.status;
              _isLoading = false;
            });
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(),
          ),
        ),
      );

  Widget _buildButton() {
    if (widget.compact) {
      return _buildCompactButton();
    }
    return _buildFullButton();
  }

  Widget _buildCompactButton() => GestureDetector(
        onTap: _handleRSVPTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getButtonColor(),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getBorderColor(),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_getTextColor()),
                  ),
                )
              else
                Icon(
                  _getButtonIcon(),
                  size: 16,
                  color: _getTextColor(),
                ),
              const SizedBox(width: 6),
              Text(
                _getButtonText(),
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildFullButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleRSVPTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getButtonColor(),
            foregroundColor: _getTextColor(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _getBorderColor(),
                width: 1.5,
              ),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_getTextColor()),
                  ),
                )
              else
                Icon(
                  _getButtonIcon(),
                  size: 20,
                ),
              const SizedBox(width: 8),
              Text(
                _getButtonText(),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRSVPOptionsSheet() => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Update your RSVP',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRSVPOption(
                    status: RSVPStatus.going,
                    title: "I'm Going",
                    subtitle: "You'll receive event reminders",
                    icon: Icons.check_circle,
                    color: const Color(0xFF4CAF50),
                  ),
                  _buildRSVPOption(
                    status: RSVPStatus.interested,
                    title: 'Interested',
                    subtitle: 'Save for later consideration',
                    icon: Icons.star,
                    color: const Color(0xFFFF9800),
                  ),
                  _buildRSVPOption(
                    status: RSVPStatus.notGoing,
                    title: "Can't Go",
                    subtitle: 'Remove from your events',
                    icon: Icons.cancel,
                    color: const Color(0xFFF44336),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildRSVPOption({
    required RSVPStatus status,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _currentStatus == status;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _updateRSVP(status);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getButtonColor() {
    switch (_currentStatus) {
      case RSVPStatus.going:
        return const Color(0xFF4CAF50);
      case RSVPStatus.interested:
        return const Color(0xFFFF9800).withValues(alpha: 0.1);
      case RSVPStatus.notGoing:
        return const Color(0xFFF44336).withValues(alpha: 0.1);
      case RSVPStatus.none:
        return AppColors.primaryGreen;
    }
  }

  Color _getBorderColor() {
    switch (_currentStatus) {
      case RSVPStatus.going:
        return const Color(0xFF4CAF50);
      case RSVPStatus.interested:
        return const Color(0xFFFF9800);
      case RSVPStatus.notGoing:
        return const Color(0xFFF44336);
      case RSVPStatus.none:
        return AppColors.primaryGreen;
    }
  }

  Color _getTextColor() {
    switch (_currentStatus) {
      case RSVPStatus.going:
        return Colors.white;
      case RSVPStatus.interested:
        return const Color(0xFFFF9800);
      case RSVPStatus.notGoing:
        return const Color(0xFFF44336);
      case RSVPStatus.none:
        return Colors.white;
    }
  }

  IconData _getButtonIcon() {
    switch (_currentStatus) {
      case RSVPStatus.going:
        return Icons.check_circle;
      case RSVPStatus.interested:
        return Icons.star;
      case RSVPStatus.notGoing:
        return Icons.cancel;
      case RSVPStatus.none:
        return Icons.add;
    }
  }

  String _getButtonText() {
    switch (_currentStatus) {
      case RSVPStatus.going:
        return widget.compact ? 'Going' : "I'm Going";
      case RSVPStatus.interested:
        return 'Interested';
      case RSVPStatus.notGoing:
        return "Can't Go";
      case RSVPStatus.none:
        return widget.compact ? 'RSVP' : "I'm Going";
    }
  }
}
