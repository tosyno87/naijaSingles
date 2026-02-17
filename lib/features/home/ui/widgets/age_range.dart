import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';

class AgeRangeWidget extends StatefulWidget {
  const AgeRangeWidget({
    required this.currentUser,
    required this.changeValues,
    super.key,
  });
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;

  @override
  State<AgeRangeWidget> createState() => _AgeRangeWidgetState();
}

class _AgeRangeWidgetState extends State<AgeRangeWidget> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          title: Text(
            'Age range'.tr().toString(),
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : AppColors.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Text(
            "${widget.currentUser.ageRange!['min']}-${widget.currentUser.ageRange!['max']}",
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: RangeSlider(
            inactiveColor: AppColors.secondaryColor,
            values: RangeValues(
              double.parse(widget.currentUser.ageRange!['min']),
              double.parse(widget.currentUser.ageRange!['max']),
            ),
            min: 18,
            max: 100,
            divisions: 25,
            activeColor: isDarkMode ? Colors.white : AppColors.primaryGreen,
            labels: RangeLabels(
              widget.currentUser.ageRange!['min'].toString(),
              widget.currentUser.ageRange!['max'].toString(),
            ),
            onChanged: (val) {
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
            },
          ),
        ),
      ),
    );
  }
}
