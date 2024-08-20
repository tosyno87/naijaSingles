import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';

class UniversityPage extends StatefulWidget {
  const UniversityPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UniversityPage createState() => _UniversityPage();
}

class _UniversityPage extends State<UniversityPage> {
  String university = '';

  @override
  Widget build(BuildContext context) {
    // for adding userdetails in this user map from navigation
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
                      "My\nuniversity is".tr().toString(),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextFormField(
                  cursorColor: primaryColor,
                  style: const TextStyle(fontSize: 23),
                  decoration: InputDecoration(
                    hintText: "Enter your university name".tr().toString(),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primaryColor)),
                    helperText:
                        "This is how it will appear in App.".tr().toString(),
                    helperStyle: TextStyle(color: secondryColor, fontSize: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      university = value;
                    });
                  },
                ),
              ),
              university.isNotEmpty
                  ? CustomButton(
                      text: "CONTINUE".tr().toString(),
                      onTap: () {
                        userData.addAll({
                          'editInfo': {
                            'university': university,
                            'userGender': userData['userGender'],
                            'showOnProfile': userData['showOnProfile']
                          }
                        });

                        log(userData.toString());
                        Navigator.pushNamed(
                            context, RouteName.profilePicSetScreen,
                            arguments: userData);
                      },
                      color: textColor,
                      active: true)
                  : CustomButton(
                      text: "CONTINUE".tr().toString(),
                      onTap: () {},
                      color: secondryColor,
                      active: themeProvider.isDarkMode ? true : false)
            ],
          ),
        ),
      ),
    );
  }
}
