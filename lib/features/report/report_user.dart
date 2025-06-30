import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../common/providers/theme_provider.dart';
import '../../models/user_model.dart';
import 'bloc/report_bloc.dart';
import 'bloc/report_events.dart';

class ReportUser extends StatefulWidget {
  final UserModel reportedBy;
  final UserModel reported;
  const ReportUser(
      {super.key, required this.reportedBy, required this.reported});
  @override
  ReportUserState createState() => ReportUserState();
}

class ReportUserState extends State<ReportUser> {
  final reasonCtlr = TextEditingController();
  final descriptionCtlr = TextEditingController();
  // bool other = false;
  bool isFeedbackDialog = false;
  String? title;

  Color get primaryColor {
    final value = Theme.of(context).primaryColor;
    return value;
  }

  String? get otherReason {
    final text = reasonCtlr.text.trim();
    if (text.isEmpty) {
      return null;
    } else {
      return text;
    }
  }

  String? get description {
    final text = descriptionCtlr.text.trim();
    if (text.isEmpty) {
      return null;
    } else {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return !isFeedbackDialog
        ? CupertinoAlertDialog(
            title: Column(
              children: <Widget>[
                Icon(
                  Icons.security,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.pink,
                  size: 35,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Report User".tr().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontFamily: 'Gellix'),
                  ),
                ),
              ],
            ),
            content: Text(
              "Is this person bothering you? Tell us what's wrong."
                  .tr()
                  .toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontFamily: 'Gellix'),
            ),
            actions:
                // !other ?
                <Widget>[
                Material(
                  child: ListTile(
                    onTap: () => changeToDescription(
                        titleValue: 'Made me uncomfortable'.tr().toString()),
                    title: Text(
                      "Made me uncomfortable".tr().toString(),
                    ),
                    leading: Icon(
                      Icons.sentiment_dissatisfied_outlined,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                  ),
                ),
                Material(
                  child: ListTile(
                    onTap: () => changeToDescription(
                        titleValue: 'Abusive or threateing'.tr().toString()),
                    title: Text(
                      "Abusive or threateing".tr().toString(),
                    ),
                    leading: Icon(
                      Icons.chat_bubble_outline,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                  ),
                ),
                Material(
                  child: ListTile(
                    onTap: () => changeToDescription(
                        titleValue: 'Inappropriate content'.tr().toString()),
                    title: Text("Inappropriate content".tr().toString()),
                    leading: Icon(
                      Icons.report_problem_outlined,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                  ),
                ),
                Material(
                  child: ListTile(
                    onTap: () => changeToDescription(
                        titleValue: 'Spam or scam'.tr().toString()),
                    title: Text(
                      "Spam or scam".tr().toString(),
                    ),
                    leading: Icon(
                      Icons.flag_outlined,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                  ),
                ),
                Material(
                  child: ListTile(
                    onTap: () => changeToDescription(
                        titleValue: 'Stolen photo'.tr().toString()),
                    title: Text(
                      "Stolen photo".tr().toString(),
                    ),
                    leading: Icon(
                      Icons.image_outlined,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                  ),
                ),
                Material(
                  child: ListTile(
                    title: Text(
                      "Other".tr().toString(),
                    ),
                    leading: Icon(
                      Icons.feedback_outlined,
                      color:
                          themeProvider.isDarkMode ? Colors.white : Colors.pink,
                    ),
                    onTap: () => changeToDescription(
                        titleValue: 'Other'.tr().toString()),
                  ),
                ),
              ])
        : CupertinoAlertDialog(
            title: Text(
              "Tell us what happend".tr().toString(),
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            content: Text(
              "Please help us ensure the safety by reporting this user. Your report is anonymous and greatly appreciated."
                  .tr()
                  .toString(),
              textAlign: TextAlign.justify,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: themeProvider.isDarkMode
                      ? Colors.white70
                      : Colors.black87),
            ),
            actions: [
              Material(
                  child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 15.0, horizontal: 20.0),
                child: Column(
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      child: TextField(
                        controller: descriptionCtlr,
                        cursorColor: const Color(0xffff3a5a),
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Color(0xffff3a5a)),
                            borderRadius:
                                BorderRadius.circular(10.0), //<-- SEE HERE
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          // filled: true,

                          hintText: "Tell us (optional)".tr().toString(),
                        ),
                      ),
                    ),
                    ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(primaryColor),
                          shape:
                              WidgetStateProperty.all(const StadiumBorder()),
                        ),
                        onPressed: () async {
                          context.read<ReportBloc>().add(ReportUserRequest(
                              moreReason: description,
                              reported: widget.reported.id!,
                              reportedBy: widget.reportedBy.id!,
                              reason: title!));

                          await showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (_) {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                });
                                return Center(
                                    child: Container(
                                        width: 150.0,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.rectangle,
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Column(
                                          children: <Widget>[
                                            Image.asset(
                                              "asset/auth/verified.jpg",
                                              height: 60,
                                              color: primaryColor,
                                              colorBlendMode: BlendMode.color,
                                            ),
                                            Text(
                                              "Reported".tr().toString(),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  decoration:
                                                      TextDecoration.none,
                                                  color:
                                                      themeProvider.isDarkMode
                                                          ? Colors.black
                                                          : Colors.black,
                                                  fontSize: 20),
                                            )
                                          ],
                                        )));
                              });
                        },
                        child: Text(
                          "Submit".tr().toString(),
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.pink,
                          ),
                        )),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel".tr().toString(),
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.pink,
                          ),
                        ))
                  ],
                ),
              )),
            ],
          );
  }

  void changeToDescription({required String titleValue}) {
    setState(() {
      isFeedbackDialog = true;
      title = titleValue;
    });
  }
}
