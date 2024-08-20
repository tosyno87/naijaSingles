import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as au;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ignore: depend_on_referenced_packages
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utlis/upload_media.dart';
import '../../../../common/widets/custom_button.dart';

class UserProfilePic extends StatefulWidget {
  const UserProfilePic({super.key});

  @override
  State<UserProfilePic> createState() => _UserProfilePicState();
}

class _UserProfilePicState extends State<UserProfilePic> {
  final au.FirebaseAuth? auth = firebaseAuthInstance;
  String? imgUrl = '';

  File? changeImageFile;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    log("user data is $userData");
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 120),
                    child: Text(
                      "Add your Image".tr().toString(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  width: double.maxFinite,
                  height: double.maxFinite,
                  alignment: Alignment.center,
                  child: Container(
                      width: 250,
                      height: 250,
                      margin: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: primaryColor),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: changeImageFile == null
                          ? IconButton(
                              color: primaryColor,
                              iconSize: 60,
                              icon: const Icon(Icons.add_a_photo),
                              onPressed: () async {
                                final file = await UploadMedia.getImage(
                                    context: context, checktype: 'profile');
                                if (file != null) {
                                  if (mounted) {
                                    setState(() {
                                      changeImageFile = file;
                                    });
                                  }
                                }
                              },
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.file(
                                changeImageFile!,
                                width: 250,
                                height: 250,
                                fit: BoxFit.fill,
                              ))),
                ),
              ),
              changeImageFile != null
                  ? CustomButton(
                      active: true,
                      color: textColor,
                      onTap: () async {
                        final file = await UploadMedia.getImage(
                            context: context, checktype: 'profile');
                        if (file != null) {
                          if (mounted) {
                            setState(() {
                              changeImageFile = file;
                            });
                          }
                        }
                      },
                      text: "CHANGE IMAGE".tr().toString(),
                    )
                  : const SizedBox.shrink(),
              changeImageFile != null
                  ? CustomButton(
                      active: true,
                      color: textColor,
                      onTap: () async {
                        log(" userdata is ${userData.toString()}");
                        Navigator.pushNamed(
                            context, RouteName.allowLocationScreen, arguments: {
                          'userData': userData,
                          'profilePic': changeImageFile
                        });
                      },
                      text: 'CONTINUE'.tr().toString(),
                    )
                  : CustomButton(
                      active: themeProvider.isDarkMode ? true : false,
                      color: secondryColor,
                      onTap: () async {},
                      text: 'CONTINUE'.tr().toString(),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
