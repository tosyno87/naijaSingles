// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hookup4u2/common/constants/colors.dart';
import 'package:hookup4u2/common/utlis/crop_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

abstract class UploadMedia {
  static Future<File?> getImage(
      {required BuildContext context, required String checktype}) async {
    final result = await _showDialogHandler(
        isImage: true, context: context, checktype: checktype);
    return result;
  }

  static Future<File> _showDialogHandler(
      {required bool isImage,
      required String checktype,
      required BuildContext context}) async {
    final result = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return _SelectMedia(
            isImage: isImage,
            checktype: checktype,
          );
        });
    return result;
  }
}

class _SelectMedia extends StatelessWidget {
  final bool isImage;
  final String checktype;
  final imagePicker = ImagePicker();
  _SelectMedia({required this.isImage, required this.checktype});
  //final cropKey = GlobalKey<CropState>();

  Future<File?> getContentHandler(
      {required ImageSource source, required BuildContext context}) async {
    try {
      final xFile = isImage
          ? await imagePicker.pickImage(source: source)
          : await imagePicker.pickVideo(
              source: source, maxDuration: const Duration(seconds: 119));

      if (xFile != null) {
        final file = File(xFile.path);

        if (isImage) {
          if (checktype == 'chat') {
            log("filechat is ${file.path}");
            return file;
          } else {
            var croppedfile = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CropMedia(title: '', file: file, checktype: checktype),
              ),
            );

            log("croppedfile is ${croppedfile.path}");
            return croppedfile;
          }
        } else {
          log("file is ${file.path}");
          return file;
        }
      }
    } catch (e) {
      log("file is in error ");
      // Navigator.pop(context);
    }

    return null;
  }

  void getContentFromSource(BuildContext context, ImageSource source) async {
    final result = await getContentHandler(source: source, context: context);
    if (result != null) {
      if (isImage) {
        var compressedImage = await compressAndGetFile(result);
        Navigator.pop(context, compressedImage);
      }
    } else {
      Navigator.pop(context);
    }
  }

  //compress file
  Future<File> compressAndGetFile(
    File file,
  ) async {
    Future<double> getImageSize(File file) async {
      final bytes = (await file.readAsBytes()).lengthInBytes;
      final kb = bytes / 1024;
      final mb = kb / 1024;
      return mb;
    }

    var imageSize = await getImageSize(file);
    log("Image Size in MB $imageSize}");

    if (imageSize <= 1) {
      //If image size is <=1 MB
      return file;
    }
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = "${dir.absolute.path}/temp.jpg";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: imageSize > 2
          ? 30
          : 50, //If image size is >2 MB the compress 70 % else 50 %
    );

    log("Image Size after Compression in MB ${await getImageSize(File(result!.path))}");
    return File(result.path);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Source".tr().toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                "Please select a source to get your content".tr().toString(),
                style: const TextStyle(fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            ButtonBar(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                    onPressed: () {
                      getContentFromSource(context, ImageSource.camera);
                    },
                    icon: Icon(
                      FontAwesomeIcons.cameraRetro,
                      color: primaryColor,
                    ),
                    label: Text(
                      "Camera".tr().toString(),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87),
                    )),
                TextButton.icon(
                  onPressed: () =>
                      getContentFromSource(context, ImageSource.gallery),
                  icon: Icon(
                    FontAwesomeIcons.images,
                    color: primaryColor,
                  ),
                  label: Text(
                    "Gallery".tr().toString(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
