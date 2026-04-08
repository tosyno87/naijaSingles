// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/image_widget.dart';
import '../../../../models/user_model.dart';
import '../../../chat/ui/screens/chat_page.dart';
import '../../../match/ui/widget/matches_card.dart';
import '../../../report/report_user.dart';
import 'gender_sign.dart';
import 'profile_action_widget.dart';
// Removed street view icon import - feature deleted
import 'unmatch_widget.dart';
// Removed street view bloc import - feature deleted

// ignore: must_be_immutable
class Info extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  Info(
    this.user,
    this.currentUser,
    this.isMatched, {
    this.controller,
    this.fromChatPage = false,
    this.fromStreetview = false,
  });
  final UserModel currentUser;
  final UserModel user;
  final bool isMatched;
  final bool fromChatPage;
  final bool fromStreetview;
  SwipableStackController? controller;

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
    final bool isMe = widget.user.id == widget.currentUser.id;
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
          color: Theme.of(context).primaryColor,
        ),
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 500,
                    width: MediaQuery.of(context).size.width,
                    child: Stack(
                      children: [
                        Swiper(
                          key: UniqueKey(),
                          physics: const ScrollPhysics(),
                          itemBuilder: (BuildContext context, int index2) =>
                              widget.user.imageUrl != null &&
                                      widget.user.imageUrl!.isNotEmpty
                                  ? Hero(
                                      tag: 'abc',
                                      child: CustomCNImage(
                                        imageUrl: widget.user.imageUrl![index2],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(),
                          itemCount: widget.user.imageUrl?.length ?? 0,
                          pagination: const SwiperPagination(
                            alignment: Alignment.bottomCenter,
                            builder: DotSwiperPaginationBuilder(
                              activeSize: 13,
                              color: AppColors.textSecondary,
                              activeColor: AppColors.primaryGreen,
                            ),
                          ),
                          control: const SwiperControl(
                            color: AppColors.primaryGreen,
                            disableColor: AppColors.textSecondary,
                          ),
                          loop: false,
                        ),
                        // Removed street view BlocBuilder - feature deleted
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ColoredBox(
                      color: Theme.of(context).primaryColor,
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            subtitle: Text('${widget.user.address}'),
                            title: Row(
                              children: [
                                Text(
                                  "${widget.user.name}, ${widget.user.editInfo!['showMyAge'] != null ? !widget.user.editInfo!['showMyAge'] ? widget.user.age : "" : widget.user.age}",
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                if (widget.user.editInfo!['showOnProfile'] ??
                                    false)
                                  GenderSign(
                                    gender: widget.user.userGender!,
                                    iconColor: AppColors.primaryGreen,
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.arrow_downward,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          if (widget.user.editInfo!['job_title'] != null)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.work,
                                color: AppColors.primaryGreen,
                              ),
                              title: Text(
                                "${widget.user.editInfo!['job_title'].toString().trim()} ${widget.user.editInfo!['company'] != null ? 'at ${widget.user.editInfo!['company'].toString().trim()}' : ''}",
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(),
                          if (widget.user.editInfo!['university'] != null)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.stars,
                                color: AppColors.primaryGreen,
                              ),
                              title: Text(
                                widget.user.editInfo!['university']
                                    .toString()
                                    .trim(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(),
                          if (widget.user.editInfo!['living_in'] != null)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.home,
                                color: AppColors.primaryGreen,
                              ),
                              title: const Text(
                                'Living in ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ).tr(
                                args: [
                                  widget.user.editInfo!['living_in']
                                      .toString()
                                      .trim(),
                                ],
                              ),
                            )
                          else
                            Container(),
                          if (!isMe)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on,
                                color: AppColors.primaryGreen,
                              ),
                              title: Text(
                                widget.user.editInfo!['DistanceVisible'] != null
                                    ? widget.user.editInfo!['DistanceVisible']
                                        ? 'Less than KM away'.tr(
                                            args: [
                                              '${widget.user.distanceBW}',
                                            ],
                                          ).toString()
                                        : 'Distance not visible'
                                    : 'Less than KM away'.tr(
                                        args: [
                                          '${widget.user.distanceBW}',
                                        ],
                                      ).toString(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(),
                          const Divider(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (widget.user.editInfo!['about'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        widget.user.editInfo!['about'].toString().trim(),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Container(),
                  const SizedBox(
                    height: 20,
                  ),
                  if (widget.user.editInfo!['about'] != null)
                    const Divider()
                  else
                    Container(),
                  if (!isMe)
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (context) => ReportUser(
                          reportedBy: widget.currentUser,
                          reported: widget.user,
                        ),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Text(
                            'REPORT'.tr(
                              args: [
                                '${widget.user.name}'.toUpperCase(),
                              ],
                            ).toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(),
                  const SizedBox(
                    height: 25,
                  ),
                  if (!isMe)
                    !widget.isMatched
                        ? UnMatcheWidget(
                            currentUser: widget.currentUser,
                            user: widget.user,
                            fromChatPage: widget.fromChatPage,
                          )
                        : Container()
                  else
                    const SizedBox.shrink(),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
            ),
            if (widget.isMatched)
              ActionWidget(
                fromStreetview: widget.fromStreetview,
                currentUser: widget.currentUser,
                user: widget.user,
                stackController: widget.controller!,
              )
            else
              isMe
                  ? FloatingButton(
                      onTap: () {
                        unawaited(
                          Navigator.pushReplacementNamed(
                            context,
                            RouteName.editProfileScreen,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.primaryGreen,
                      ),
                    )
                  : FloatingButton(
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => ChatPage(
                                sender: widget.currentUser,
                                second: widget.user,
                                chatId: chatId(
                                  widget.user,
                                  widget.currentUser,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.message,
                        color: AppColors.primaryGreen,
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
