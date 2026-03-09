import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constants/app_colors.dart';

class CustomToast {
  static void showToast(
    String msg,
  ) {
    unawaited(Fluttertoast.cancel());
    unawaited(
      Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.primaryGreen,
        textColor: Colors.white,
        fontSize: 16,
      ),
    );
  }
}
