import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../common/constants/colors.dart';
import '../../../../../common/providers/theme_provider.dart';

class FaceBookButton extends StatelessWidget {
  final VoidCallback onTap;
  const FaceBookButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Material(
        elevation: 2.0,
        borderRadius: const BorderRadius.all(Radius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: InkWell(
              onTap: onTap,
              child: Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(25),
                      gradient: !themeProvider.isDarkMode
                          ? LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                  primaryColor.withOpacity(.5),
                                  primaryColor.withOpacity(.8),
                                  primaryColor,
                                  primaryColor
                                ])
                          : LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [primaryColor, primaryColor])),
                  height: MediaQuery.of(context).size.height * .065,
                  width: MediaQuery.of(context).size.width * .8,
                  child: Center(
                      child: Text(
                    "LOG IN WITH FACEBOOK".tr().toString(),
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                  )))),
        ),
      ),
    );
  }
}
