// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';

class AgeRangeWidget extends StatefulWidget {
  final UserModel currentUser;
  Map<String, dynamic> changeValues;
  AgeRangeWidget(
      {super.key, required this.currentUser, required this.changeValues});

  @override
  State<AgeRangeWidget> createState() => _AgeRangeWidgetState();
}

class _AgeRangeWidgetState extends State<AgeRangeWidget> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
            title: Text(
              "Age range".tr().toString(),
              style: TextStyle(
                  fontSize: 18,
                  color: themeProvider.isDarkMode ? Colors.white : primaryColor,
                  fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              "${widget.currentUser.ageRange!['min']}-${widget.currentUser.ageRange!['max']}",
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: RangeSlider(
                inactiveColor: secondryColor,
                values: RangeValues(
                    double.parse(widget.currentUser.ageRange!['min']),
                    (double.parse(widget.currentUser.ageRange!['max']))),
                min: 18.0,
                max: 100.0,
                divisions: 25,
                activeColor:
                    themeProvider.isDarkMode ? Colors.white : primaryColor,
                labels: RangeLabels(
                  widget.currentUser.ageRange!['min'].toString(),
                  widget.currentUser.ageRange!['max'].toString(),
                ),
                onChanged: (val) {
                  widget.changeValues.addAll({
                    'age_range': {
                      'min': '${val.start.truncate()}',
                      'max': '${val.end.truncate()}'
                    }
                  });
                  setState(() {
                    widget.currentUser.ageRange = {
                      'min': val.start.toInt().toString(),
                      'max': val.end.toInt().toString()
                    };
                  });
                })),
      ),
    );
  }
}
