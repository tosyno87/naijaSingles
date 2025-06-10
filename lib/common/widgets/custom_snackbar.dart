import 'package:flutter/material.dart';

class CustomSnackbar {
  // ignore: avoid_types_as_parameter_names, non_constant_identifier_names
  // static showSnackBar(msg, context, title, ContentType, Color color) {
  //   ScaffoldMessenger.of(context).removeCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     elevation: 0,
  //     behavior: SnackBarBehavior.floating,
  //     backgroundColor: Colors.transparent,
  //     showCloseIcon: false,
  //     // ignore: sized_box_for_whitespace
  //     content: Container(
  //       height: 70,
  //       child: AwesomeSnackbarContent(
  //           messageFontSize: 14,
  //           titleFontSize: 18,
  //           color: color,
  //           title: title,
  //           message: msg,
  //           contentType: ContentType),
  //     ),
  //   ));
  // }

  static showSnackBarSimple(String msg, BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            content: Text(
              msg,
              style: const TextStyle(color: Colors.white, fontFamily: "Gellix"),
            ),
            action: SnackBarAction(
              label: "DISMISS",
              onPressed: () {
                try {
                  ScaffoldMessenger.of(context).clearSnackBars();
                } catch (e) {
                  rethrow;
                }
              },
            )),
      );
  }

  // static showSnackBarSimple(msg, context) {
  //   ScaffoldMessenger.of(context).removeCurrentSnackBar();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         msg,
  //         style: const TextStyle(
  //           color: Colors.white,
  //         ),
  //       ),
  //       // duration: const Duration(seconds: 1),
  //       behavior: SnackBarBehavior.fixed,
  //       elevation: 3.0,
  //       backgroundColor: primaryColor,
  //     ),
  //   );
  // }
}
