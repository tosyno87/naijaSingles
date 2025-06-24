import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/features/user/ui/widgets/gender_sign.dart';
import 'package:naijasingles/features/user/ui/widgets/profile_action_widget.dart';
import 'package:naijasingles/features/user/ui/widgets/sexual_orientation_widget.dart';
// Removed street view icon import - feature deleted
import 'package:naijasingles/features/user/ui/widgets/unmatch_widget.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widgets/image_widget.dart';
import '../../../chat/ui/screens/chat_page.dart';
import '../../../match/ui/widget/matches_card.dart';
import '../../../report/report_user.dart';
// Removed street view bloc import - feature deleted

// ignore: must_be_immutable
class Info extends StatefulWidget {
  final UserModel currentUser;
  final UserModel user;
  final bool isMatched;
  final bool fromChatPage;
  final bool fromStreetview;
  SwipableStackController? controller;
  // ignore: use_key_in_widget_constructors
  Info(this.user, this.currentUser, this.isMatched,
      {this.controller,
      this.fromChatPage = false,
      this.fromStreetview = false});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  void initState() {
    // Removed street view bloc initialization - feature deleted
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = widget.user.id == widget.currentUser.id;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Container(
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50), topRight: Radius.circular(50)),
            color: Theme.of(context).primaryColor),
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 500,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(children: [
                      Swiper(
                        key: UniqueKey(),
                        physics: const ScrollPhysics(),
                        itemBuilder: (BuildContext context, int index2) {
                          // ignore: unnecessary_null_comparison
                          return widget.user.imageUrl!.length != null
                              ? Hero(
                                  tag: "abc",
                                  child: CustomCNImage(
                                    imageUrl: widget.user.imageUrl![index2],
                                    fit: BoxFit.cover,
                                  ))
                              : Container();
                        },
                        itemCount: widget.user.imageUrl!.length,
                        pagination: SwiperPagination(
                            alignment: Alignment.bottomCenter,
                            builder: DotSwiperPaginationBuilder(
                                activeSize: 13,
                                color: textSecondary,
                                activeColor: primaryColor)),
                        control: SwiperControl(
                          color: primaryColor,
                          disableColor: textSecondary,
                        ),
                        loop: false,
                      ),
                      // Removed street view BlocBuilder - feature deleted
                    ]),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Theme.of(context).primaryColor,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            subtitle: Text("${widget.user.address}"),
                            title: Row(
                              children: [
                                Text(
                                  "${widget.user.name}, ${widget.user.editInfo!['showMyAge'] != null ? !widget.user.editInfo!['showMyAge'] ? widget.user.age : "" : widget.user.age}",
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                widget.user.editInfo!['showOnProfile'] ?? false
                                    ? GenderSign(
                                        gender: widget.user.userGender!,
                                        iconColor: primaryColor,
                                      )
                                    : const SizedBox.shrink()
                              ],
                            ),
                            trailing: IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: Icon(
                                  Icons.arrow_downward,
                                  color: primaryColor,
                                )),
                          ),
                          widget.user.sexualOrientation!['showOnProfile']
                              ? ListTile(
                                  dense: true,
                                  leading: Image.asset(
                                    'asset/gender.png',
                                    color: primaryColor,
                                    height: 24,
                                  ),
                                  title: FirebasesexualDataWidget(
                                    data: widget
                                        .user.sexualOrientation!['orientation'],
                                  ))
                              : Container(),
                          widget.user.editInfo!['job_title'] != null
                              ? ListTile(
                                  dense: true,
                                  leading:
                                      Icon(Icons.work, color: primaryColor),
                                  title: Text(
                                    "${widget.user.editInfo!['job_title'].toString().trim()} ${widget.user.editInfo!['company'] != null ? 'at ${widget.user.editInfo!['company'].toString().trim()}' : ''}",
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )
                              : Container(),
                          widget.user.editInfo!['university'] != null
                              ? ListTile(
                                  dense: true,
                                  leading:
                                      Icon(Icons.stars, color: primaryColor),
                                  title: Text(
                                    widget.user.editInfo!['university']
                                        .toString()
                                        .trim(),
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )
                              : Container(),
                          widget.user.editInfo!['living_in'] != null
                              ? ListTile(
                                  dense: true,
                                  leading:
                                      Icon(Icons.home, color: primaryColor),
                                  title: Text(
                                    "Living in ",
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ).tr(args: [
                                    (widget.user.editInfo!['living_in']
                                        .toString()
                                        .trim())
                                  ]),
                                )
                              : Container(),
                          !isMe
                              ? ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.location_on,
                                    color: primaryColor,
                                  ),
                                  title: Text(
                                    widget.user.editInfo!['DistanceVisible'] !=
                                            null
                                        ? widget.user
                                                .editInfo!['DistanceVisible']
                                            ? 'Less than KM away'.tr(args: [
                                                "${widget.user.distanceBW}"
                                              ]).toString()
                                            : 'Distance not visible'
                                        : 'Less than KM away'.tr(args: [
                                            "${widget.user.distanceBW}"
                                          ]).toString(),
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500),
                                  ),
                                )
                              : Container(),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  widget.user.editInfo!['about'] != null
                      ? Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Text(
                            widget.user.editInfo!['about'].toString().trim(),
                            style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        )
                      : Container(),
                  const SizedBox(
                    height: 20,
                  ),
                  widget.user.editInfo!['about'] != null
                      ? const Divider()
                      : Container(),
                  !isMe
                      ? InkWell(
                          onTap: () => showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (context) => ReportUser(
                                  reportedBy: widget.currentUser,
                                  reported: widget.user)),
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Text(
                                  "REPORT".tr(args: [
                                    "${widget.user.name}".toUpperCase()
                                  ]).toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary),
                                ),
                              )),
                        )
                      : Container(),
                  const SizedBox(
                    height: 25,
                  ),
                  !isMe
                      ? !widget.isMatched
                          ? UnMatcheWidget(
                              currentUser: widget.currentUser,
                              user: widget.user,
                              fromChatPage: widget.fromChatPage,
                            )
                          : Container()
                      : const SizedBox.shrink(),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
            widget.isMatched
                ? ActionWidget(
                    fromStreetview: widget.fromStreetview,
                    currentUser: widget.currentUser,
                    user: widget.user,
                    stackController: widget.controller!,
                  )
                : isMe
                    ? FloatingButton(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                              context, RouteName.editProfileScreen);
                        },
                        icon: Icon(
                          Icons.edit,
                          color: primaryColor,
                        ))
                    : FloatingButton(
                        onTap: () {
                          Navigator.push(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => ChatPage(
                                        sender: widget.currentUser,
                                        second: widget.user,
                                        chatId: chatId(
                                            widget.user, widget.currentUser),
                                      )));
                        },
                        icon: Icon(
                          Icons.message,
                          color: primaryColor,
                        ))
          ],
        ),
      ),
    );
  }
}
