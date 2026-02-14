import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/colors.dart';
import '../../../../models/user_model.dart';

class DistanceWidget extends StatefulWidget {
  const DistanceWidget({
    required this.currentUser,
    required this.max,
    required this.changeValues,
    super.key,
  });
  final UserModel currentUser;
  final Map<String, dynamic> changeValues;
  final double max;

  @override
  State<DistanceWidget> createState() => _DistanceWidgetState();
}

class _DistanceWidgetState extends State<DistanceWidget> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ListTile(
          title: Text(
            'Maximum distance'.tr().toString(),
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode ? Colors.white : primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Text(
            '${(widget.currentUser.maxDistance! * 0.621371).round()} mi.',
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Slider(
            value: widget.currentUser.maxDistance!.toDouble(),
            inactiveColor: AppColors.secondaryColor,
            min: 1,
            max: widget.max,
            activeColor: isDarkMode ? Colors.white : primaryColor,
            onChanged: (val) {
              widget.changeValues.addAll({'maximum_distance': val.round()});
              setState(() {
                widget.currentUser.maxDistance = val.round();
              });
            },
          ),
        ),
      ),
    );
  }
}
