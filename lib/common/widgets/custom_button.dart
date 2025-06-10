import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final bool active;

  const CustomButton(
      {super.key,
      required this.text,
      required this.onTap,
      required this.color,
      required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: InkWell(
            onTap: onTap,
            child: Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(25),
                  // gradient: active
                  //     ? LinearGradient(
                  //         begin: Alignment.topRight,
                  //         end: Alignment.bottomLeft,
                  //         colors: [
                  //             primaryColor.withOpacity(.5),
                  //             primaryColor.withOpacity(.7),
                  //             primaryColor,
                  //             primaryColor
                  //           ])
                  //     : const LinearGradient(
                  //         begin: Alignment.topRight,
                  //         end: Alignment.bottomLeft,
                  //         colors: [Colors.white, Colors.white])
                ),
                height: MediaQuery.of(context).size.height * .065,
                width: MediaQuery.of(context).size.width * .75,
                child: Center(
                    child: Text(
                  text.tr().toString(),
                  style: TextStyle(
                      fontSize: 15, color: color, fontWeight: FontWeight.bold),
                )))),
      ),
    );
  }
}
