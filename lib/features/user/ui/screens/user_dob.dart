// ignore_for_file: sort_child_properties_last

import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/routes/route_name.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/custom_button.dart';

class UserDOB extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserDOB(this.userData, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserDOBState createState() => _UserDOBState();
}

class _UserDOBState extends State<UserDOB> {
  // String userDOB = '';
  DateTime selecteddate = DateTime(1999, 10, 19);
  DateTime initialDate = DateTime(1999, 10, 19);
  TextEditingController dobctlr = TextEditingController();

  @override
  void initState() {
    dobctlr.text =
        '${initialDate.day}/${initialDate.month}/${initialDate.year}';

    super.initState();
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
                Navigator.pop(context);
              },
              child: IconButton(
                iconSize: 20,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
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
                    child: Text(
                      "My\nbirthday is".tr().toString(),
                      style: const TextStyle(fontSize: 40),
                    ),
                    padding: const EdgeInsets.only(left: 50, top: 120),
                  ),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: ListTile(
                    title: CupertinoTextField(
                      readOnly: true,
                      decoration: kDefaultRoundedBorderDecoration,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : secondryColor),
                      prefix: IconButton(
                        icon: (Icon(
                          Icons.calendar_today,
                          color: primaryColor,
                        )),
                        onPressed: () {},
                      ),
                      onTap: () => showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * .25,
                                child: GestureDetector(
                                  child: CupertinoDatePicker(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    initialDateTime: DateTime(1999, 10, 19),
                                    onDateTimeChanged: (DateTime newdate) {
                                      setState(() {
                                        dobctlr.text =
                                            '${newdate.day}/${newdate.month}/${newdate.year}';
                                        selecteddate = newdate;
                                      });
                                    },
                                    maximumYear: 2002,
                                    minimumYear: 1800,
                                    maximumDate: DateTime(2002, 03, 12),
                                    mode: CupertinoDatePickerMode.date,
                                  ),
                                  onTap: () {
                                    log(dobctlr.text);
                                    Navigator.pop(context);
                                  },
                                ));
                          }),
                      placeholder: "DD/MM/YYYY",
                      controller: dobctlr,
                    ),
                    subtitle: Text("Your age will be public".tr().toString()),
                  )),
              CustomButton(
                active: true,
                color: textColor,
                onTap: () {
                  widget.userData.addAll({
                    'user_DOB': "$selecteddate",
                    'age': ((DateTime.now().difference(selecteddate).inDays) /
                            365.2425)
                        .truncate(),
                  });
                  log(widget.userData.toString());
                  Navigator.pushNamed(context, RouteName.genderScreen,
                      arguments: widget.userData);
                },
                text: 'CONTINUE',
              )
            ],
          ),
        ),
      ),
    );
  }
}
