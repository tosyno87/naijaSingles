import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/theme_provider.dart';

class ChangeThemeButtonWidget extends StatelessWidget {
  const ChangeThemeButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    ThemeMode currentThemeMode = themeProvider.themeMode;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Center(
              child: Text(
                'Change Theme'.tr().toString(),
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500),
              ),
            ),
            InkResponse(
              child: !themeProvider.isDarkMode
                  ? Icon(
                      Icons.wb_sunny,
                      color: primaryColor,
                    )
                  : Icon(
                      Icons.nightlight_round,
                      color: primaryColor,
                    ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text('Select Theme Mode'.tr().toString()),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              RadioListTile<ThemeMode>(
                                title: Text('System Default'.tr().toString()),
                                value: ThemeMode.system,
                                activeColor: primaryColor,
                                groupValue: currentThemeMode,
                                onChanged: (ThemeMode? value) {
                                  setState(() {
                                    currentThemeMode = value!;
                                  });

                                  log("theme $value");
                                },
                              ),
                              RadioListTile<ThemeMode>(
                                title: Text('Light'.tr().toString()),
                                activeColor: primaryColor,
                                value: ThemeMode.light,
                                groupValue: currentThemeMode,
                                onChanged: (ThemeMode? value) {
                                  setState(() {
                                    currentThemeMode = value!;
                                  });
                                  log("theme $value");
                                },
                              ),
                              RadioListTile<ThemeMode>(
                                title: Text('Dark'.tr().toString()),
                                activeColor: primaryColor,
                                value: ThemeMode.dark,
                                groupValue: currentThemeMode,
                                onChanged: (ThemeMode? value) {
                                  setState(() {
                                    currentThemeMode = value!;
                                  });
                                  log("theme $value");
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Cancel'.tr().toString(),
                            style: TextStyle(color: secondryColor),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Apply'.tr().toString(),
                            style: TextStyle(color: primaryColor),
                          ),
                          onPressed: () {
                            final provider = Provider.of<ThemeProvider>(context,
                                listen: false);
                            provider.toggleTheme(currentThemeMode);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            )
          ]),
        ),
      ),
    );
  }
}
