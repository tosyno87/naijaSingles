import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/custom_button.dart';
import '../../../../common/widets/custom_snackbar.dart';

class SexualOrientation extends StatefulWidget {
  const SexualOrientation({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SexualOrientationState createState() => _SexualOrientationState();
}

class _SexualOrientationState extends State<SexualOrientation> {
  List<Map<String, dynamic>> orientationlist = [
    {'name': 'Straight'.tr().toString(), 'ontap': false},
    {'name': 'Gay'.tr().toString(), 'ontap': false},
    {'name': 'Asexual'.tr().toString(), 'ontap': false},
    {'name': 'Lesbian'.tr().toString(), 'ontap': false},
    {'name': 'Bisexual'.tr().toString(), 'ontap': false},
    {'name': 'Demisexual'.tr().toString(), 'ontap': false},
  ];
  List selected = [];
  bool select = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
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
            padding: const EdgeInsets.only(top: 5.0, left: 0),
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
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 60, top: 100),
                child: Text(
                  "My sexual\norientation is".tr().toString(),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: orientationlist.length,
                  itemBuilder: (BuildContext context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: OutlinedButton(
                        //   highlightedBorderColor: primaryColor,
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * .055,
                          width: MediaQuery.of(context).size.width * .65,
                          child: Center(
                              child: Text("${orientationlist[index]["name"]}",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: orientationlist[index]["ontap"]
                                          ? primaryColor
                                          : secondryColor,
                                      fontWeight: FontWeight.bold))),
                        ),

                        onPressed: () {
                          setState(() {
                            if (selected.length < 3) {
                              orientationlist[index]["ontap"] =
                                  !orientationlist[index]["ontap"];
                              if (orientationlist[index]["ontap"]) {
                                selected.add(orientationlist[index]["name"]);
                                log(orientationlist[index]["name"]);
                                log(selected.toString());
                              } else {
                                selected.remove(orientationlist[index]["name"]);
                                log(selected.toString());
                              }
                            } else {
                              if (orientationlist[index]["ontap"]) {
                                orientationlist[index]["ontap"] =
                                    !orientationlist[index]["ontap"];
                                selected.remove(orientationlist[index]["name"]);
                              } else {
                                CustomSnackbar.showSnackBarSimple(
                                  "select upto 3",
                                  context,
                                );
                              }
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Checkbox(
                          activeColor: primaryColor,
                          value: select,
                          onChanged: (newValue) {
                            setState(() {
                              select = newValue!;
                            });
                          },
                        ),
                        title: Text("Show my orientation on my profile"
                            .tr()
                            .toString()),
                      ),
                      selected.isNotEmpty
                          ? CustomButton(
                              text: "CONTINUE".tr().toString(),
                              onTap: () {
                                userData.addAll({
                                  "sexualOrientation": {
                                    'orientation': selected,
                                    'showOnProfile': select
                                  },
                                });
                                log(userData.toString());
                                Navigator.pushNamed(
                                    context, RouteName.showGenderScreen,
                                    arguments: userData);
                              },
                              color: textColor,
                              active: true)
                          : CustomButton(
                              text: "CONTINUE".tr().toString(),
                              onTap: () {
                                CustomSnackbar.showSnackBarSimple(
                                  "please select one".tr().toString(),
                                  context,
                                );
                              },
                              color: secondryColor,
                              active: themeProvider.isDarkMode ? true : false,
                            )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
