import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Reusable styled text field for authentication and form screens
/// Provides consistent styling with white container, shadow, and validation border
class AfropeepTextField extends StatefulWidget {

  const AfropeepTextField({
    required this.controller, required this.hintText, super.key,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.showValidationBorder = true,
    this.validationChecker,
  });
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;
  final bool showValidationBorder;
  final bool Function(String)? validationChecker;

  @override
  State<AfropeepTextField> createState() => _AfropeepTextFieldState();
}

class _AfropeepTextFieldState extends State<AfropeepTextField> {
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateValidationState);
    _updateValidationState();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateValidationState);
    super.dispose();
  }

  void _updateValidationState() {
    if (!widget.showValidationBorder) return;

    final text = widget.controller.text.trim();
    bool isValid = false;

    if (widget.validationChecker != null) {
      isValid = widget.validationChecker!(text);
    } else if (widget.validator != null) {
      // If validator exists, check if it would pass
      final error = widget.validator!(text);
      isValid = error == null && text.isNotEmpty;
    } else {
      isValid = text.isNotEmpty;
    }

    if (mounted && _isValid != isValid) {
      setState(() {
        _isValid = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.validator != null &&
        widget.controller.text.isNotEmpty &&
        widget.validator!(widget.controller.text) != null;

    return Container(
      height: 60,
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
        border: widget.showValidationBorder
            ? Border.all(
                color: hasError
                    ? AppColors.error
                    : _isValid
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                width: hasError || _isValid ? 1.5 : 0,
              )
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        onChanged: (_) {
          if (widget.showValidationBorder) {
            _updateValidationState();
          }
          widget.onChanged?.call();
        },
        style: GoogleFonts.montserrat(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.montserrat(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: AppColors.primaryGreen,
                )
              : null,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}

