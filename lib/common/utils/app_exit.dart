import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Future<bool> onWillPop(BuildContext context) async =>
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Exit'.tr().toString()),
        content: Text('Do you want to exit the app?'.tr().toString()),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No'.tr().toString(),
              style: const TextStyle(color: AppColors.primaryGreen),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Yes'.tr().toString(),
              style: const TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    ) ??
    false;
