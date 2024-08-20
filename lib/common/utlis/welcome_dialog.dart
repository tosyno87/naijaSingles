import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import '../constants/colors.dart';

Future showWelcomDialog(context) async {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, RouteName.tabScreen);
        });
        return Center(
            child: Container(
                width: 150.0,
                height: 100.0,
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      "asset/auth/verified.jpg",
                      height: 60,
                      color: primaryColor,
                      colorBlendMode: BlendMode.color,
                    ),
                    Text(
                      "You'r in".tr().toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.black,
                          fontSize: 20),
                    )
                  ],
                )));
      });
}
