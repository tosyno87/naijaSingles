// ignore_for_file: unused_import

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';

class Gender extends StatefulWidget {
  const Gender({super.key});

  @override
  GenderState createState() => GenderState();
}

class GenderState extends State<Gender> {
  bool men = false;
  bool women = false;
  bool other = false;
  bool select = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Map<String, Object> userGender;
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    log(userData.toString());
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).primaryColor,
      floatingActionButton: SizedBox(
        height: 45,
        width: 45,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 50),
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: FloatingActionButton(
              elevation: 1,
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.black : Colors.white,
              onPressed: () {
                dispose();
                Navigator.pop(context);
              },
              child: IconButton(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                iconSize: 20,
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 120),
            child: Text(
              "I am a".tr().toString(),
              style: const TextStyle(fontSize: 40),
            ),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                OutlinedButton(
                  //   highlightedBorderColor: primaryColor,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * .065,
                    width: MediaQuery.of(context).size.width * .75,
                    child: Center(
                        child: Text("MAN".tr().toString(),
                            style: TextStyle(
                                fontSize: 20,
                                color: men ? primaryColor : secondryColor,
                                fontWeight: FontWeight.bold))),
                  ),

                  onPressed: () {
                    setState(() {
                      women = false;
                      men = true;
                      other = false;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: OutlinedButton(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * .065,
                      width: MediaQuery.of(context).size.width * .75,
                      child: Center(
                          child: Text("WOMAN".tr().toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: women ? primaryColor : secondryColor,
                                  fontWeight: FontWeight.bold))),
                    ),
                    onPressed: () {
                      setState(() {
                        women = true;
                        men = false;
                        other = false;
                      });
                      // Navigator.push(
                      //     context, CupertinoPageRoute(builder: (context) => OTP()));
                    },
                  ),
                ),
                OutlinedButton(
                  // focusColor: primaryColor,
                  // highlightedBorderColor: primaryColor,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * .065,
                    width: MediaQuery.of(context).size.width * .75,
                    child: Center(
                        child: Text("OTHER".tr().toString(),
                            style: TextStyle(
                                fontSize: 20,
                                color: other ? primaryColor : secondryColor,
                                fontWeight: FontWeight.bold))),
                  ),

                  onPressed: () {
                    setState(() {
                      women = false;
                      men = false;
                      other = true;
                    });
                    // Navigator.push(
                    //     context, CupertinoPageRoute(builder: (context) => OTP()));
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 100.0, left: 10),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: Checkbox(
                  activeColor: primaryColor,
                  value: select,
                  onChanged: (newValue) {
                    setState(() {
                      select = newValue!;
                    });
                  },
                ),
                title: Text("Show my gender on my profile".tr().toString()),
              ),
            ),
          ),
          men || women || other
              ? CustomButton(
                  text: "CONTINUE",
                  onTap: () {
                    if (men) {
                      userGender = {
                        'userGender': "men",
                        'showOnProfile': select
                      };
                    } else if (women) {
                      userGender = {
                        'userGender': "women",
                        'showOnProfile': select
                      };
                    } else {
                      userGender = {
                        'userGender': "other",
                        'showOnProfile': select
                      };
                    }
                    userData.addAll(userGender);
                    // log(userData['userGender']['showOnProfile'].toString());
                    Navigator.pushNamed(
                        context, RouteName.sexualorientationScreen,
                        arguments: userData);
                    //      ads.disable(ad1);
                  },
                  color: textColor,
                  active: true,
                )
              : CustomButton(
                  text: "CONTINUE",
                  onTap: () {
                    CustomSnackbar.showSnackBarSimple(
                        "please select one".tr().toString(), context);
                  },
                  color: secondryColor,
                  active: themeProvider.isDarkMode ? true : false,
                )
        ],
      ),
    );
  }
}
