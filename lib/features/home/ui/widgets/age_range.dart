import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

class AgeRangeWidget extends StatefulWidget {
  const AgeRangeWidget({
    required this.currentUser,
    required this.changeValues,
    this.compact = false,
    this.onEdited,
    super.key,
  });
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  final bool compact;
  final VoidCallback? onEdited;

  @override
  State<AgeRangeWidget> createState() => _AgeRangeWidgetState();
}

class _AgeRangeWidgetState extends State<AgeRangeWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 6 : 8),
        child: ListTile(
          visualDensity:
              widget.compact ? VisualDensity.compact : VisualDensity.standard,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 4 : 8,
          ),
          title: Text(
            'Age range'.tr().toString(),
            style: TextStyle(
              fontSize: widget.compact ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Text(
            "${widget.currentUser.ageRange!['min']}-${widget.currentUser.ageRange!['max']}",
            style: TextStyle(
              fontSize: widget.compact ? 16 : 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: RangeSlider(
            inactiveColor: AppColors.secondaryColor,
            values: RangeValues(
              double.parse(widget.currentUser.ageRange!['min']),
              double.parse(widget.currentUser.ageRange!['max']),
            ),
            min: 18,
            max: 100,
            activeColor: isDarkMode ? Colors.white : AppColors.primaryGreen,
            labels: RangeLabels(
              widget.currentUser.ageRange!['min'].toString(),
              widget.currentUser.ageRange!['max'].toString(),
            ),
            onChanged: (RangeValues val) {
              widget.changeValues.addAll({
                'age_range': {
                  'min': '${val.start.truncate()}',
                  'max': '${val.end.truncate()}',
                },
              });
              setState(() {
                widget.currentUser.ageRange = {
                  'min': val.start.toInt().toString(),
                  'max': val.end.toInt().toString(),
                };
              });
              widget.onEdited?.call();
            },
          ),
        ),
      ),
    );
  }
}
