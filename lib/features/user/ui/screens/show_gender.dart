// ignore_for_file: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/custom_snackbar.dart';

class ShowGender extends StatefulWidget {
  const ShowGender({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ShowGenderState createState() => _ShowGenderState();
}

class _ShowGenderState extends State<ShowGender> {
  bool men = false;
  bool women = false;
  bool eyeryone = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    // for adding userdetails in this user map from navigation
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final themeProvider = Provider.of<ThemeProvider>(context);
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
              "Show me".tr().toString(),
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
                        child: Text("MEN".tr().toString(),
                            style: TextStyle(
                                fontSize: 20,
                                color: men ? primaryColor : secondryColor,
                                fontWeight: FontWeight.bold))),
                  ),

                  onPressed: () {
                    setState(() {
                      women = false;
                      men = true;
                      eyeryone = false;
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
                          child: Text("WOMEN".tr().toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: women ? primaryColor : secondryColor,
                                  fontWeight: FontWeight.bold))),
                    ),
                    onPressed: () {
                      setState(() {
                        women = true;
                        men = false;
                        eyeryone = false;
                      });
                    },
                  ),
                ),
                OutlinedButton(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * .065,
                    width: MediaQuery.of(context).size.width * .75,
                    child: Center(
                        child: Text("EVERYONE".tr().toString(),
                            style: TextStyle(
                                fontSize: 20,
                                color: eyeryone ? primaryColor : secondryColor,
                                fontWeight: FontWeight.bold))),
                  ),
                  onPressed: () {
                    setState(() {
                      women = false;
                      men = false;
                      eyeryone = true;
                    });
                  },
                ),
              ],
            ),
          ),
          men || women || eyeryone
              ? CustomButton(
                  text: "CONTINUE",
                  onTap: () {
                    if (men) {
                      userData.addAll({'showGender': "men"});
                    } else if (women) {
                      userData.addAll({'showGender': "women"});
                    } else {
                      userData.addAll({'showGender': "everyone"});
                    }

                    log(userData.toString());
                    Navigator.pushNamed(context, RouteName.universityScreen,
                        arguments: userData);
                  },
                  color: textColor,
                  active: true)
              : CustomButton(
                  text: "CONTINUE",
                  onTap: () {
                    CustomSnackbar.showSnackBarSimple(
                      "please select one".tr().toString(),
                      context,
                    );
                  },
                  color: secondryColor,
                  active: themeProvider.isDarkMode ? true : false)
        ],
      ),
    );
  }
}
