// ignore: file_names
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/theme_provider.dart';

class TextButtonWidget extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;
  const TextButtonWidget(
      {super.key, required this.text, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: Text(
                        text.tr().toString(),
                        style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(
                      icon,
                      size: 24,
                      color: primaryColor,
                    )
                  ]),
            ),
          )),
    );
  }
}
