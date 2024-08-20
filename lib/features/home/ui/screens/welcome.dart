import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  Map<String, dynamic> userData = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .8,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(
                          height: 150,
                        ),
                        Text(
                          "hookup4u",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 35,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            "Welcome to hookup4u.\nPlease follow these House Rules."
                                .tr()
                                .toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            "Be yourself.".tr().toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Make sure your photos, age, and bio are true to who you are."
                                .tr()
                                .toString(),
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            "Play it cool.".tr().toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Respect other and treat them as you would like to be treated"
                                .tr()
                                .toString(),
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            "Stay safe.".tr().toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Don't be too quick to give out personal information."
                                .tr()
                                .toString(),
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          title: Text(
                            "Be proactive.".tr().toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Always report bad behavior.".tr().toString(),
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40, top: 50),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    child: CustomButton(
                        text: "GOT IT".tr().toString(),
                        onTap: () async {
                          // this run when user login from facebook

                          final user = firebaseAuthInstance.currentUser!;
                          if (user.displayName != null) {
                            if (user.displayName!.isNotEmpty) {
                              log(user.displayName.toString());
                              userData.addAll({'UserName': user.displayName});
                              Navigator.pushNamed(
                                  context, RouteName.userDobScreen,
                                  arguments: userData);
                            } else {
                              log("no user name saved yet");
                              Navigator.pushNamed(
                                  context, RouteName.userNameScreen);
                            }
                          } else {
                            log("by default coming users");
                            Navigator.pushNamed(
                                context, RouteName.userNameScreen);
                          }
                        },
                        color: textColor,
                        active: true),
                  ),
                ),
              )
            ],
          ),
        ));
  }
}
