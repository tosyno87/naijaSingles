import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/route_name.dart';

Future<void> showWelcomDialog(BuildContext context) async {
  unawaited(
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        unawaited(
          Future.delayed(const Duration(seconds: 3), () {
            if (!context.mounted) return;
            Navigator.pop(ctx);
            unawaited(Navigator.pushNamed(context, RouteName.mainNavigation));
          }),
        );
        return Center(
          child: Container(
            width: 150,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: <Widget>[
                Image.asset(
                  'asset/auth/verified.jpg',
                  height: 60,
                  color: AppColors.primaryGreen,
                  colorBlendMode: BlendMode.color,
                ),
                Text(
                  "You'r in".tr().toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
