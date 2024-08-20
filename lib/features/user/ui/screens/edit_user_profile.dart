// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/widets/image_widget.dart';
import 'package:hookup4u2/features/user/bloc/update_user_state.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/utlis/upload_media.dart';
import '../../../../common/widets/custom_button.dart';
import '../../../../common/widets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../bloc/update_user_bloc.dart';
import '../../bloc/user_event.dart';

class EditProfile extends StatefulWidget {
  final UserModel currentUser;
  const EditProfile(this.currentUser, {super.key});

  @override
  EditProfileState createState() => EditProfileState();
}

// comment
class EditProfileState extends State<EditProfile> {
  final TextEditingController aboutCtlr = TextEditingController();
  final TextEditingController companyCtlr = TextEditingController();
  final TextEditingController livingCtlr = TextEditingController();
  final TextEditingController jobCtlr = TextEditingController();
  final TextEditingController universityCtlr = TextEditingController();
  bool visibleAge = false;
  bool visibleDistance = true;
  final _madeChanges = ValueNotifier(false);
  var showMe = 'man';
  Map<String, dynamic> editInfo = {};

  @override
  void initState() {
    super.initState();
    log('---------------------${widget.currentUser.phoneNumber}');
    aboutCtlr.text = widget.currentUser.editInfo!['about'] ?? '';
    companyCtlr.text = widget.currentUser.editInfo!['company'] ?? '';
    livingCtlr.text = widget.currentUser.editInfo!['living_in'] ?? '';
    universityCtlr.text = widget.currentUser.editInfo!['university'] ?? '';
    jobCtlr.text = widget.currentUser.editInfo!['job_title'] ?? '';

    setState(() {
      showMe = widget.currentUser.editInfo!['userGender'] ?? '';
      visibleAge = widget.currentUser.editInfo!['showMyAge'] ?? false;
      visibleDistance = widget.currentUser.editInfo!['DistanceVisible'] ?? true;
    });

    super.initState();
  }

  Future<bool> _onWillPop() async {
    final currentstate = BlocProvider.of<UserBloc>(context).state;
    if (currentstate == UpdatingUser()) {
      log("coming under updating state");
      return false;
    }

    if (editInfo.isNotEmpty) {
      return (await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Save Changes?".tr().toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Close".tr().toString(),
                      style: TextStyle(color: primaryColor)),
                ),
                TextButton(
                  onPressed: () async {
                    if (editInfo.isNotEmpty) {
                      BlocProvider.of<UserBloc>(context)
                          .add(UpdateUserRequest(details: editInfo));
                    } else {
                      editInfo.clear();
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text("Save".tr().toString(),
                      style: TextStyle(color: primaryColor)),
                ),
              ],
            ),
          )) ??
          false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const BorderSide kDefaultRoundedBorderSide = BorderSide(
      color: CupertinoDynamicColor.withBrightness(
        color: Color(0x33000000),
        darkColor: Color(0x33FFFFFF),
      ),
      width: 0.0,
    );
    const Border kDefaultRoundedBorder = Border(
      top: kDefaultRoundedBorderSide,
      bottom: kDefaultRoundedBorderSide,
      left: kDefaultRoundedBorderSide,
      right: kDefaultRoundedBorderSide,
    );
    BoxDecoration kDefaultRoundedBorderDecoration = BoxDecoration(
      color: CupertinoDynamicColor.withBrightness(
        color: CupertinoColors.white,
        darkColor: Theme.of(context).primaryColor,
      ),
      border: kDefaultRoundedBorder,
      borderRadius: const BorderRadius.all(Radius.circular(5.0)),
    );
    return BlocListener<UserBloc, UserStates>(
      listener: (context, state) {
        if (state is UpdatingUser) {
          CustomSnackbar.showSnackBarSimple(
              "Loading..".tr().toString(), context);
        } else if (state is UpdatingUserProfilePicture) {
          CustomSnackbar.showSnackBarSimple(
              "Uploading media..".tr().toString(), context);
        } else if (state is UserProfilePictureUploaded) {
          CustomSnackbar.showSnackBarSimple(
              "Media added successfully..".tr().toString(), context);

          _madeChanges.value = false;
        } else if (state is UserUpdationFailed) {
          CustomSnackbar.showSnackBarSimple(state.message, context);
        } else if (state is UserUpdated) {
          CustomSnackbar.showSnackBarSimple(
              "Profile Updated!".tr().toString(), context);
          log("updated succesfully user ....".tr().toString());
          _madeChanges.value = false;
          editInfo.clear();

          // editInfo.clear();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
            elevation: 0,
            automaticallyImplyLeading: true,
            title: Text(
              "Edit Profile".tr().toString(),
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor),
        body: PopScope(
          canPop: false,
          onPopInvoked: (bool didPop) async {
            if (didPop) {
              return;
            }
            final NavigatorState navigator = Navigator.of(context);
            final bool shouldPop = await _onWillPop();
            if (shouldPop) {
              navigator.pop();
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).primaryColor,
            body: Container(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  color: Theme.of(context).primaryColor),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        height: MediaQuery.of(context).size.height * .65,
                        width: MediaQuery.of(context).size.width,
                        child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            childAspectRatio:
                                MediaQuery.of(context).size.aspectRatio * 1.5,
                            crossAxisSpacing: 4,
                            padding: const EdgeInsets.all(10),
                            children: List.generate(9, (index) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: widget
                                                .currentUser.imageUrl!.length >
                                            index
                                        ? BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          )
                                        : BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                style: BorderStyle.solid,
                                                width: 1,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.white
                                                    : secondryColor)),
                                    child: Stack(
                                      children: <Widget>[
                                        widget.currentUser.imageUrl!.length >
                                                index
                                            ? CustomCNImage(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    .2,
                                                main: true,
                                                fit: BoxFit.cover,
                                                imageUrl: widget.currentUser
                                                        .imageUrl![index] ??
                                                    '',
                                              )
                                            : Container(),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: widget.currentUser
                                                            .imageUrl!.length >
                                                        index
                                                    ? Colors.white
                                                    : primaryColor,
                                              ),
                                              child: widget.currentUser
                                                          .imageUrl!.length >
                                                      index
                                                  ? InkWell(
                                                      child: Icon(
                                                        Icons.cancel,
                                                        color: primaryColor,
                                                        size: 22,
                                                      ),
                                                      onTap: () async {
                                                        if (widget
                                                                .currentUser
                                                                .imageUrl!
                                                                .length >
                                                            1) {
                                                          _deletePicture(index);
                                                        } else {
                                                          // Check if there is only one image available

                                                          // Add a new image
                                                          final file =
                                                              await UploadMedia
                                                                  .getImage(
                                                                      context:
                                                                          context,
                                                                      checktype:
                                                                          'addMedia');

                                                          BlocProvider.of<
                                                                      UserBloc>(
                                                                  context)
                                                              .add(
                                                            UpdateUserProfilePictures(
                                                              checktype:
                                                                  'addMedia',
                                                              photo: file!,
                                                              currentUser: widget
                                                                  .currentUser,
                                                            ),
                                                          );
                                                          if (widget
                                                                  .currentUser
                                                                  .imageUrl!
                                                                  .length ==
                                                              1) {
                                                            // Delete the first image
                                                            _deletePicture(0);
                                                          }

                                                          _madeChanges.value =
                                                              true;
                                                        }
                                                      },
                                                    )
                                                  : InkWell(
                                                      child: const Icon(
                                                        Icons
                                                            .add_circle_outline,
                                                        size: 22,
                                                        color: Colors.white,
                                                      ),
                                                      onTap: () async {
                                                        final file =
                                                            await UploadMedia
                                                                .getImage(
                                                                    context:
                                                                        context,
                                                                    checktype:
                                                                        'addMedia');

                                                        BlocProvider.of<
                                                                    UserBloc>(
                                                                context)
                                                            .add(
                                                          UpdateUserProfilePictures(
                                                              checktype:
                                                                  'addMedia',
                                                              photo: file!,
                                                              currentUser: widget
                                                                  .currentUser),
                                                        );

                                                        _madeChanges.value =
                                                            true;

                                                        log("myinfo${editInfo.toString()}");
                                                      })),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })),
                      ),
                      InkWell(
                        child: Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            height: 50,
                            width: 340,
                            child: Center(
                                child: Text(
                              "Add media".tr().toString(),
                              style: TextStyle(
                                  fontSize: 15,
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ))),
                        onTap: () async {
                          if (widget.currentUser.imageUrl!.length < 9) {
                            final file = await UploadMedia.getImage(
                                context: context, checktype: 'addMedia');

                            BlocProvider.of<UserBloc>(context).add(
                              UpdateUserProfilePictures(
                                  checktype: 'addMedia',
                                  photo: file!,
                                  currentUser: widget.currentUser),
                            );

                            _madeChanges.value = true;
                          } else {
                            CustomSnackbar.showSnackBarSimple(
                                "You can upload upto 9 images".tr().toString(),
                                context);
                          }
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListBody(
                            mainAxis: Axis.vertical,
                            children: <Widget>[
                              ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    "About",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ).tr(args: ['${widget.currentUser.name}']),
                                ),
                                subtitle: CupertinoTextField(
                                  decoration: kDefaultRoundedBorderDecoration,
                                  controller: aboutCtlr,
                                  cursorColor: primaryColor,
                                  maxLines: null,
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : secondryColor),
                                  placeholder: "About you".tr().toString(),
                                  placeholderStyle: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? secondryColor
                                          : secondryColor),
                                  padding: const EdgeInsets.all(10),
                                  onChanged: (text) {
                                    editInfo.addAll({'about': text});
                                    _madeChanges.value = true;
                                  },
                                ),
                              ),
                              ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    "Job title".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                                subtitle: CupertinoTextField(
                                  decoration: kDefaultRoundedBorderDecoration,
                                  controller: jobCtlr,
                                  cursorColor: primaryColor,
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : secondryColor),
                                  placeholder: "Add job title".tr().toString(),
                                  placeholderStyle: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? secondryColor
                                          : secondryColor),
                                  padding: const EdgeInsets.all(10),
                                  onChanged: (text) {
                                    editInfo.addAll({'job_title': text});
                                    _madeChanges.value = true;
                                  },
                                ),
                              ),
                              ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    "Company".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                                subtitle: CupertinoTextField(
                                  decoration: kDefaultRoundedBorderDecoration,
                                  controller: companyCtlr,
                                  placeholderStyle: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? secondryColor
                                          : secondryColor),
                                  cursorColor: primaryColor,
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : secondryColor),
                                  placeholder: "Add company".tr().toString(),
                                  padding: const EdgeInsets.all(10),
                                  onChanged: (text) {
                                    editInfo.addAll({'company': text});
                                    _madeChanges.value = true;
                                  },
                                ),
                              ),
                              ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    "University".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                                subtitle: CupertinoTextField(
                                  decoration: kDefaultRoundedBorderDecoration,
                                  controller: universityCtlr,
                                  cursorColor: primaryColor,
                                  placeholderStyle: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? secondryColor
                                          : secondryColor),
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : secondryColor),
                                  placeholder: "Add university".tr().toString(),
                                  padding: const EdgeInsets.all(10),
                                  onChanged: (text) {
                                    editInfo.addAll({'university': text});
                                    _madeChanges.value = true;
                                    log("updated some detais ....$editInfo");
                                  },
                                ),
                              ),
                              ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 5.0),
                                  child: Text(
                                    "Living in".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                                subtitle: CupertinoTextField(
                                  decoration: kDefaultRoundedBorderDecoration,
                                  controller: livingCtlr,
                                  cursorColor: primaryColor,
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white70
                                          : secondryColor),
                                  placeholderStyle: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? secondryColor
                                          : secondryColor),
                                  placeholder: "Add city".tr().toString(),
                                  padding: const EdgeInsets.all(10),
                                  onChanged: (text) {
                                    editInfo.addAll({'living_in': text});
                                    _madeChanges.value = true;
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  title: Text(
                                    "I am".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                  subtitle: DropdownButton(
                                    iconEnabledColor: primaryColor,
                                    iconDisabledColor: secondryColor,
                                    isExpanded: true,
                                    style: TextStyle(
                                        color: themeProvider.isDarkMode
                                            ? Colors.white70
                                            : secondryColor),
                                    items: [
                                      DropdownMenuItem(
                                        value: "men",
                                        child: Text("Men".tr().toString()),
                                      ),
                                      DropdownMenuItem(
                                          value: "women",
                                          child: Text("Women".tr().toString())),
                                      DropdownMenuItem(
                                          value: "other",
                                          child: Text("Other".tr().toString())),
                                    ],
                                    onChanged: (val) {
                                      editInfo.addAll({'userGender': val});
                                      _madeChanges.value = true;
                                      setState(() {
                                        showMe = val!;
                                      });
                                    },
                                    value: showMe,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              ListTile(
                                  title: Text(
                                    "Control your profile".tr().toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                  subtitle: Card(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text("Don't Show My Age"
                                                  .tr()
                                                  .toString()),
                                            ),
                                            Switch(
                                                activeColor: primaryColor,
                                                value: visibleAge,
                                                onChanged: (value) {
                                                  editInfo.addAll(
                                                      {'showMyAge': value});
                                                  _madeChanges.value = true;
                                                  setState(() {
                                                    visibleAge = value;
                                                  });
                                                })
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                  "Make My Distance Visible"
                                                      .tr()
                                                      .toString()),
                                            ),
                                            Switch(
                                                activeColor: primaryColor,
                                                value: visibleDistance,
                                                onChanged: (value) {
                                                  editInfo.addAll({
                                                    'DistanceVisible': value
                                                  });
                                                  _madeChanges.value = true;
                                                  log("updated distance visible details ....$editInfo");
                                                  setState(() {
                                                    visibleDistance = value;
                                                  });
                                                })
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: ValueListenableBuilder<bool>(
                                      valueListenable: _madeChanges,
                                      builder: (context, value, child) {
                                        if (value) {
                                          return BlocBuilder<UserBloc,
                                                  UserStates>(
                                              builder: (context, state) {
                                            if (state is UpdatingUser) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 50.0, right: 50),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.rectangle,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              25),
                                                      color: primaryColor,
                                                    ),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            .065,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .75,
                                                    child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ))),
                                              );
                                            }
                                            return CustomButton(
                                                color: textColor,
                                                active: (editInfo.isNotEmpty)
                                                    ? true
                                                    : false,
                                                onTap: () async {
                                                  FocusManager
                                                      .instance.primaryFocus
                                                      ?.unfocus();

                                                  if (editInfo.isNotEmpty) {
                                                    log("updated all detais 1....$editInfo");

                                                    log("updated all detais without image ....$editInfo");
                                                    BlocProvider.of<UserBloc>(
                                                            context)
                                                        .add(UpdateUserRequest(
                                                      details: editInfo,
                                                    ));
                                                  }
                                                },
                                                text: 'Save'.tr().toString());
                                          });
                                        }
                                        return Opacity(
                                          opacity: .7,
                                          child: CustomButton(
                                            text: 'Save'.tr().toString(),
                                            color: Colors.white,
                                            active: false,
                                            onTap: () {},
                                          ),
                                        );
                                      })),
                              const SizedBox(
                                height: 100,
                              )
                            ]),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deletePicture(int index) async {
    if (widget.currentUser.imageUrl![index] != null) {
      try {
        Reference ref = FirebaseStorage.instance
            .refFromURL(widget.currentUser.imageUrl![index]);
        log(ref.fullPath);
        await ref.delete();
      } catch (e) {
        rethrow;
      }
    }

    widget.currentUser.imageUrl!.removeAt(index);

    await firebaseFireStoreInstance
        .collection("Users")
        .doc(widget.currentUser.id)
        .set({
      "Pictures": widget.currentUser.imageUrl,
    }, SetOptions(merge: true));

    setState(() {
      // Update the UI if necessary
    });
  }
}
