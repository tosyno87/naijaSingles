import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

class ShowmeWidget extends StatefulWidget {
  const ShowmeWidget({
    required this.currentUser,
    required this.changeValues,
    this.compact = false,
    this.onEdited,
    super.key,
  });
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  /// Tighter padding for dense filter screens (e.g. discovery preferences).
  final bool compact;
  final VoidCallback? onEdited;

  @override
  State<ShowmeWidget> createState() => _ShowmeWidgetState();
}

class _ShowmeWidgetState extends State<ShowmeWidget> {
  static const List<String> _values = <String>['men', 'women', 'everyone'];

  String _effectiveValue() {
    final String? raw = widget.currentUser.showGender?.toLowerCase().trim();
    if (raw == 'men' || raw == 'women' || raw == 'everyone') {
      return raw!;
    }
    return 'everyone';
  }

  String _labelFor(String value) {
    switch (value) {
      case 'men':
        return 'Men'.tr();
      case 'women':
        return 'Women'.tr();
      case 'everyone':
        return 'Everyone'.tr();
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = widget.compact
        ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
        : const EdgeInsets.all(10);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color onSurface = scheme.onSurface;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fieldFill = isDark
        ? scheme.onSurface.withValues(alpha: 0.10)
        : Colors.grey.shade50;
    final Color fieldBorder = isDark
        ? scheme.onSurface.withValues(alpha: 0.34)
        : Colors.grey.shade400;
    final Color valueTextColor = onSurface;
    final Color chevronEnabled =
        isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen;
    final Color chevronDisabled = scheme.onSurface.withValues(alpha: 0.38);
    final EdgeInsets fieldPadding = EdgeInsets.symmetric(
      horizontal: 12,
      vertical: widget.compact ? 10 : 14,
    );

    return Card(
      child: Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Show me'.tr(),
              style: TextStyle(
                fontSize: widget.compact ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            SizedBox(height: widget.compact ? 8 : 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fieldBorder),
              ),
              child: Padding(
                padding: fieldPadding,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    iconSize: 28,
                    iconEnabledColor: chevronEnabled,
                    iconDisabledColor: chevronDisabled,
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(
                      fontSize: widget.compact ? 16 : 15,
                      fontWeight: FontWeight.w600,
                      color: valueTextColor,
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return _values.map((String v) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _labelFor(v),
                            style: TextStyle(
                              fontSize: widget.compact ? 17 : 16,
                              fontWeight: FontWeight.w700,
                              color: valueTextColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: _values
                        .map(
                          (String v) => DropdownMenuItem<String>(
                            value: v,
                            child: Text(
                              _labelFor(v),
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (String? val) {
                      if (val == null) return;
                      widget.changeValues
                          .addAll(<String, Object?>{'showGender': val});
                      setState(() {
                        widget.currentUser.showGender = val;
                      });
                      widget.onEdited?.call();
                    },
                    value: _effectiveValue(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
