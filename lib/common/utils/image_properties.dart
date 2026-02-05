import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as i;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/user_model.dart';
import '../bloc/theme/theme_bloc.dart';
import '../constants/colors.dart';
import '../constants/constants.dart';

class ImageProperties {
  static Future<File> compressImage(CroppedFile image) async {
    try {
      final File croppedToFileImage = File(image.path);
      final tempdir = await getTemporaryDirectory();
      final path = tempdir.path;

      final bytes = await croppedToFileImage.readAsBytes();
      final i.Image? imagefile = i.decodeImage(bytes);

      if (imagefile == null) {
        throw Exception('Failed to decode image');
      }

      final compressedImagefile =
          File('$path/${DateTime.now().millisecondsSinceEpoch}.jpg')
            ..writeAsBytesSync(i.encodeJpg(imagefile, quality: 80));

      return compressedImagefile;
    } catch (e) {
      log('Error compressing image: $e');
      rethrow;
    }
  }

  static Future<void> source(
    BuildContext context,
    UserModel currentUser,
    bool isProfilePicture,
  ) async {
    final isDarkMode = context.read<ThemeBloc>().isDarkMode;
    return showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(
          isProfilePicture
              ? 'Update profile picture'.tr()
              : 'Add pictures'.tr(),
        ),
        content: Text('Select source'.tr()),
        actions: canUploadMoreImages(currentUser)
            ? <Widget>[
                _buildSourceOption(
                  icon: Icons.photo_camera,
                  label: ' Camera'.tr(),
                  isDarkMode: isDarkMode,
                  onTap: () => _handleImageSource(
                    context,
                    currentUser,
                    isProfilePicture,
                    ImageSource.camera,
                  ),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: ' Gallery'.tr(),
                  isDarkMode: isDarkMode,
                  onTap: () => _handleImageSource(
                    context,
                    currentUser,
                    isProfilePicture,
                    ImageSource.gallery,
                  ),
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        const Icon(Icons.error),
                        Text(
                          "Can't upload more than $maxImagesAllowed pictures"
                              .tr(),
                          style: TextStyle(
                            fontSize: 15,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.black,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  static Future<void> getImage(
    ImageSource imageSource,
    BuildContext context,
    UserModel currentUser,
    bool isProfilePicture,
  ) async {
    final ImagePicker imagePicker = ImagePicker();
    try {
      final XFile? image = await imagePicker.pickImage(source: imageSource);
      if (image == null) {
        if (context.mounted) {
          Navigator.pop(context);
        }
        return;
      }

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1,
            title: 'Crop',
          ),
        ],
      );

      if (croppedFile != null) {
        await uploadFile(
          await compressImage(croppedFile),
          currentUser,
          isProfilePicture,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      log('Error getting image: $e');
      if (context.mounted) {
        Navigator.pop(context);
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: ${e.toString()}')),
        );
      }
    }
  }

  static Future<void> uploadFile(
    File image,
    UserModel currentUser,
    bool isProfilePicture,
  ) async {
    try {
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.id}/${image.hashCode}.jpg');

      final UploadTask uploadTask = storageReference.putFile(image);

      final snapshot = await uploadTask;
      final fileURL = await snapshot.ref.getDownloadURL();

      final Map<String, dynamic> updateObject = {
        'Pictures': FieldValue.arrayUnion([fileURL]),
      };

      if (isProfilePicture) {
        if (currentUser.imageUrl?.isNotEmpty ?? false) {
          currentUser.imageUrl?.removeAt(0);
        }
        currentUser.imageUrl?.insert(0, fileURL);

        await firebaseFireStoreInstance
            .collection('users')
            .doc(currentUser.id)
            .set({'Pictures': currentUser.imageUrl}, SetOptions(merge: true));
      } else {
        await firebaseFireStoreInstance
            .collection('users')
            .doc(currentUser.id)
            .set(updateObject, SetOptions(merge: true));
        currentUser.imageUrl?.add(fileURL);
      }
    } on Exception catch (e) {
      log('Error uploading file: $e');
      rethrow;
    }
  }

  static Future<File> urlToFile(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      final tempdir = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempdir.path}/$fileName');

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } on Exception catch (e) {
      log('Error downloading image from URL: $e');
      rethrow;
    }
  }

  static Future<File> downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      final documentDirectory = await getApplicationDocumentsDirectory();
      final file = File(
        '${documentDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } on Exception catch (e) {
      log('Error downloading file: $e');
      rethrow;
    }
  }

  /// Helper method to build source option buttons
  static Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) =>
      Padding(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 28),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode ? Colors.white : Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      );

  /// Helper method to handle image source selection
  static void _handleImageSource(
    BuildContext context,
    UserModel currentUser,
    bool isProfilePicture,
    ImageSource source,
  ) {
    Navigator.pop(context);
    showDialog(
      barrierDismissible: source != ImageSource.gallery,
      context: context,
      builder: (context) {
        getImage(source, context, currentUser, isProfilePicture);
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );
  }

  /// Validates if user can upload more images
  static bool canUploadMoreImages(UserModel user) =>
      (user.imageUrl?.length ?? 0) < 9;

  /// Gets the maximum number of images allowed
  static int get maxImagesAllowed => 9;
}
