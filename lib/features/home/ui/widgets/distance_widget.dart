import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

class DistanceWidget extends StatefulWidget {
  const DistanceWidget({
    required this.currentUser,
    required this.max,
    required this.changeValues,
    this.compact = false,
    this.onEdited,
    super.key,
  });
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  final double max;
  final bool compact;
  final VoidCallback? onEdited;

  @override
  State<DistanceWidget> createState() => _DistanceWidgetState();
}

class _DistanceWidgetState extends State<DistanceWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 4 : 5),
        child: ListTile(
          visualDensity:
              widget.compact ? VisualDensity.compact : VisualDensity.standard,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 4 : 8,
          ),
          title: Text(
            'Maximum distance'.tr().toString(),
            style: TextStyle(
              fontSize: widget.compact ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Text(
            '${(widget.currentUser.maxDistance! * 0.621371).round()} ${'mi'.tr()}',
            style: TextStyle(
              fontSize: widget.compact ? 16 : 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Slider(
            value: widget.currentUser.maxDistance!.toDouble(),
            inactiveColor: AppColors.secondaryColor,
            min: 1,
            max: widget.max,
            activeColor: isDarkMode ? Colors.white : AppColors.primaryGreen,
            onChanged: (double val) {
              widget.changeValues.addAll({'maximum_distance': val.round()});
              setState(() {
                widget.currentUser.maxDistance = val.round();
              });
              widget.onEdited?.call();
            },
          ),
        ),
      ),
    );
  }
}
