// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../models/user_model.dart';

class DistanceWidget extends StatefulWidget {
  final UserModel currentUser;
  Map<String, dynamic> changeValues;
  double max;
  DistanceWidget(
      {super.key,
      required this.currentUser,
      required this.max,
      required this.changeValues});

  @override
  State<DistanceWidget> createState() => _DistanceWidgetState();
}

class _DistanceWidgetState extends State<DistanceWidget> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListTile(
          title: Text(
            "Maximum distance".tr().toString(),
            style: TextStyle(
                fontSize: 18,
                color: themeProvider.isDarkMode ? Colors.white : primaryColor,
                fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            "${widget.currentUser.maxDistance} Km.",
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Slider(
              value: widget.currentUser.maxDistance!.toDouble(),
              inactiveColor: secondryColor,
              min: 1.0,
              max: widget.max,
              activeColor:
                  themeProvider.isDarkMode ? Colors.white : primaryColor,
              onChanged: (val) {
                widget.changeValues.addAll({'maximum_distance': val.round()});
                setState(() {
                  widget.currentUser.maxDistance = val.round();
                });
              }),
        ),
      ),
    );
  }
}
