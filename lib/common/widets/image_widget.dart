// ignore_for_file: must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class CustomCNImage extends StatelessWidget {
  String? imageUrl;
  double? height;
  double? width;
  bool main;
  BoxFit? fit;
  CustomCNImage(
      {super.key,
      required this.imageUrl,
      this.height,
      this.fit,
      this.width,
      this.main = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CachedNetworkImage(
      fit: fit,
      maxHeightDiskCache: 800,
      maxWidthDiskCache: 800,
      imageUrl: imageUrl ?? '',
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => const Center(
        child: CupertinoActivityIndicator(
          radius: 15,
        ),
      ),
      errorWidget: (context, url, error) => !main
          ? const Icon(
              Icons.error,
              color: Colors.black,
              size: 23,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.error,
                  color: Colors.black,
                  size: 20,
                ),
                Text(
                  "Unable to load".tr().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                )
              ],
            ),
      height: height,
      width: width,
    );
  }
}
