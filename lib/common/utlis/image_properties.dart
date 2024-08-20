import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/providers/theme_provider.dart';
import 'package:image/image.dart' as i;
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';

class ImageProperties {
  static Future compressimage(CroppedFile image) async {
    final File croppedToFileImage = File(image.path);
    final tempdir = await getTemporaryDirectory();
    final path = tempdir.path;
    i.Image? imagefile = i.decodeImage(croppedToFileImage.readAsBytesSync());
    final compressedImagefile = File('$path.jpg')
      ..writeAsBytesSync(i.encodeJpg(imagefile!, quality: 80));
    // setState(() {
    return compressedImagefile;
    // });
  }

  static Future source(
      BuildContext context, currentUser, bool isProfilePicture) async {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
              title: Text(isProfilePicture
                  ? "Update profile picture".tr().toString()
                  : "Add pictures".tr().toString()),
              content: Text(
                "Select source".tr().toString(),
              ),
              insetAnimationCurve: Curves.decelerate,
              actions: currentUser.imageUrl.length < 9
                  ? <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GestureDetector(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.photo_camera,
                                size: 28,
                              ),
                              Text(
                                " Camera".tr().toString(),
                                style: TextStyle(
                                    fontSize: 15,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    decoration: TextDecoration.none),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                                context: context,
                                builder: (context) {
                                  getImage(ImageSource.camera, context,
                                      currentUser, isProfilePicture);
                                  return const Center(
                                      child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ));
                                });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: GestureDetector(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(
                                Icons.photo_library,
                                size: 28,
                              ),
                              Text(
                                " Gallery".tr().toString(),
                                style: TextStyle(
                                    fontSize: 15,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    decoration: TextDecoration.none),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  getImage(ImageSource.gallery, context,
                                      currentUser, isProfilePicture);
                                  return const Center(
                                      child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ));
                                });
                          },
                        ),
                      ),
                    ]
                  : [
                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Center(
                            child: Column(
                          children: <Widget>[
                            const Icon(Icons.error),
                            Text(
                              "Can't uplaod more than 9 pictures"
                                  .tr()
                                  .toString(),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  decoration: TextDecoration.none),
                            ),
                          ],
                        )),
                      )
                    ]);
        });
  }

  static Future getImage(
      ImageSource imageSource, context, currentUser, isProfilePicture) async {
    ImagePicker imagePicker = ImagePicker();
    try {
      var image = await imagePicker.pickImage(source: imageSource);
      if (image != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: [CropAspectRatioPreset.square],
          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop',
                toolbarColor: primaryColor,
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: true),
            IOSUiSettings(
              minimumAspectRatio: 1.0,
              title: 'Crop',
            )
          ],
        );

        if (croppedFile != null) {
          await uploadFile(
              await compressimage(croppedFile), currentUser, isProfilePicture);
        }
      }

      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
    }
  }

  static Future uploadFile(
      File image, UserModel currentUser, isProfilePicture) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('users/${currentUser.id}/${image.hashCode}.jpg');
    UploadTask uploadTask = storageReference.putFile(image);
    //if (uploadTask.isInProgress == true) {}
    //if (await uploadTask.onComplete != null) {
    await uploadTask.whenComplete(() {
      storageReference.getDownloadURL().then((fileURL) async {
        Map<String, dynamic> updateObject = {
          "Pictures": FieldValue.arrayUnion([
            fileURL,
          ])
        };
        try {
          if (isProfilePicture) {
            currentUser.imageUrl!.removeAt(0);
            currentUser.imageUrl!.insert(0, fileURL);
            log("object");
            await firebaseFireStoreInstance
                .collection("Users")
                .doc(currentUser.id)
                .set({"Pictures": currentUser.imageUrl},
                    SetOptions(merge: true));
          } else {
            await firebaseFireStoreInstance
                .collection("Users")
                .doc(currentUser.id)
                .set(updateObject, SetOptions(merge: true));
            currentUser.imageUrl!.add(fileURL);
          }
        } catch (err) {
          rethrow;
        }
      });
    });
  }

  static Future<File> urlToFile(String imageUrl) async {
    var response = await http.get(Uri.parse(imageUrl));
    var filePath = imageUrl.split('/').last;
    var file = File(filePath);
    return file.writeAsBytes(response.bodyBytes);
  }

  static Future<File> downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));

    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File(
        '${documentDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await file.writeAsBytes(response.bodyBytes);

    return file;
  }
}
