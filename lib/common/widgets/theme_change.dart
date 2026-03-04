import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme/theme_bloc.dart';
import '../constants/app_colors.dart';

class ChangeThemeButtonWidget extends StatelessWidget {
  const ChangeThemeButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.watch<ThemeBloc>();
    ThemeMode currentThemeMode =
        themeBloc.currentThemeMode ?? ThemeMode.system;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Center(
                child: Text(
                  'Change Theme'.tr().toString(),
                  style: TextStyle(
                    color:
                        themeBloc.isDarkMode ? Colors.white : AppColors.primaryGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkResponse(
                child: !themeBloc.isDarkMode
                    ? const Icon(
                        Icons.wb_sunny,
                        color: AppColors.primaryGreen,
                      )
                    : const Icon(
                        Icons.nightlight_round,
                        color: AppColors.primaryGreen,
                      ),
                onTap: () {
                  unawaited(showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) => AlertDialog(
                      title: Text('Select Theme Mode'.tr().toString()),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) =>
                            Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            RadioListTile<ThemeMode>(
                              title: Text('System Default'.tr().toString()),
                              value: ThemeMode.system,
                              activeColor: AppColors.primaryGreen,
                              groupValue: currentThemeMode,
                              onChanged: (ThemeMode? value) {
                                setState(() {
                                  currentThemeMode = value!;
                                });

                                log('theme $value');
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text('Light'.tr().toString()),
                              activeColor: AppColors.primaryGreen,
                              value: ThemeMode.light,
                              groupValue: currentThemeMode,
                              onChanged: (ThemeMode? value) {
                                setState(() {
                                  currentThemeMode = value!;
                                });
                                log('theme $value');
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text('Dark'.tr().toString()),
                              activeColor: AppColors.primaryGreen,
                              value: ThemeMode.dark,
                              groupValue: currentThemeMode,
                              onChanged: (ThemeMode? value) {
                                setState(() {
                                  currentThemeMode = value!;
                                });
                                log('theme $value');
                              },
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Cancel'.tr().toString(),
                            style: const TextStyle(
                                color: AppColors.secondaryColor,),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Apply'.tr().toString(),
                            style: const TextStyle(color: AppColors.primaryGreen),
                          ),
                          onPressed: () {
                            context
                                .read<ThemeBloc>()
                                .add(ThemeModeChanged(currentThemeMode));
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    ),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
