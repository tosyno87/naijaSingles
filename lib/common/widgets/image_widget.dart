import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme/theme_bloc.dart';

class CustomCNImage extends StatelessWidget {
  const CustomCNImage({
    required this.imageUrl,
    super.key,
    this.height,
    this.fit,
    this.width,
    this.main = false,
  });
  final String? imageUrl;
  final double? height;
  final double? width;
  final bool main;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
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
                  'Unable to load'.tr().toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
      height: height,
      width: width,
    );
  }
}
