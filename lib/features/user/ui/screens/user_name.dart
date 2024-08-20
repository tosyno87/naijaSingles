//import 'package:firebase_admob/firebase_admob.dart';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/providers/theme_provider.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widets/custom_button.dart';

class UserName extends StatefulWidget {
  const UserName({super.key});

  @override
  UserNameState createState() => UserNameState();
}

// late BannerAd ad1;
// Ads ads = new Ads();

class UserNameState extends State<UserName> {
  Map<String, dynamic> userData = {}; //user personal info
  String username = '';

  @override
  void initState() {
    //  ad1 = ads.myBanner();
    super.initState();
    // ad1
    //   ..load()
    //   ..show(
    //     anchorOffset: 180.0,
    //     anchorType: AnchorType.bottom,
    //   );
  }

  @override
  void dispose() {
    // ads.disable(ad1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
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
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 50, top: 120),
                    child: Text(
                      "My first\nname is".tr().toString(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: TextFormField(
                  cursorColor: primaryColor,
                  style: const TextStyle(fontSize: 23),
                  decoration: InputDecoration(
                    hintText: "Enter your first name".tr().toString(),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primaryColor)),
                    helperText:
                        "This is how it will appear in App.".tr().toString(),
                    helperStyle: TextStyle(color: secondryColor, fontSize: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      username = value;
                    });
                  },
                ),
              ),
              username.isNotEmpty
                  ? CustomButton(
                      active: true,
                      color: Colors.white,
                      onTap: () {
                        userData.addAll({'UserName': username});
                        log(userData.toString());
                        Navigator.pushNamed(context, RouteName.userDobScreen,
                            arguments: userData);
                      },
                      text: 'CONTINUE'.tr().toString(),
                    )
                  : CustomButton(
                      active: themeProvider.isDarkMode ? true : false,
                      color: secondryColor,
                      onTap: () {
                        CustomSnackbar.showSnackBarSimple(
                            "Please enter name", context);
                      },
                      text: 'CONTINUE'.tr().toString(),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
