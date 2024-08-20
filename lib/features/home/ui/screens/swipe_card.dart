import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u2/features/user/ui/widgets/user_info.dart';
import 'package:provider/provider.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/image_widget.dart';
import '../../../../models/user_model.dart';
import '../../../ads/google_ads.dart';
import '../../../ads/load_ads.dart';
import '../../../user/ui/widgets/card_level.dart';
import '../../../user/ui/widgets/gender_sign.dart';

// import 'MatchedAnimation.dart';

class UsersList extends StatefulWidget {
  final UserModel currentUser;
  final List<UserModel> users;

  final List<UserModel> usersList;

  final SwipableStackController? stackController;
  final Function(int, SwipeDirection) onswiped;

  // var _controller = SimpleAnimation('match');
  const UsersList(
      {super.key,
      required this.users,
      required this.usersList,
      required this.currentUser,
      required this.stackController,
      required this.onswiped});

  @override
  UsersListState createState() => UsersListState();
}

class UsersListState extends State<UsersList> with WidgetsBindingObserver {
  //Ads _ads = new Ads();
  InterstitialAd? interstitialAd;
  bool isInterstitialAdReady = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.stackController?.addListener(() {
      if (widget.usersList.length == widget.stackController?.currentIndex) {
        if (mounted) setState(() {});
        debugPrint('this is the last profile');
      }
    });
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ));

    super.initState();
  }

  @override
  void dispose() {
    interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return widget.usersList.length == widget.stackController?.currentIndex
        ? Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    radius: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        "asset/hookup4u-Logo-BP.png",
                        fit: BoxFit.contain,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  "There's no one new around you.".tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black54,
                      fontStyle: FontStyle.normal,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                      fontSize: 20),
                )
              ],
            ),
          )
        : SwipableStack(
            horizontalSwipeThreshold: 0.8,
            verticalSwipeThreshold: 0.8,
            overlayBuilder: (context, properties) {
              final opacity = min(properties.swipeProgress, 1.0);
              if (properties.direction == SwipeDirection.right) {
                return Padding(
                  padding: const EdgeInsets.only(top: 25, left: 25),
                  child: Opacity(opacity: opacity, child: CardLabel.right()),
                );
              } else if (properties.direction == SwipeDirection.left) {
                return Padding(
                  padding: const EdgeInsets.only(top: 25, right: 25),
                  child: Opacity(opacity: opacity, child: CardLabel.left()),
                );
              }
              return Container();
            },
            itemCount: widget.usersList.length,
            onWillMoveNext: (index, direction) {
              final allowedActions = [
                SwipeDirection.right,
                SwipeDirection.left,
              ];
              return allowedActions.contains(direction);
            },
            builder: (context, index) {
              final itemIndex = index.index;

              return Stack(
                children: <Widget>[
                  ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        height: MediaQuery.of(context).size.height * .80,
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          child: Container(
                            color: Colors.white,
                            child: CustomCNImage(
                              imageUrl:
                                  widget.users[itemIndex].imageUrl!.first ?? "",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 15, right: 15),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20)),
                              gradient: LinearGradient(
                                  colors: [
                                    Colors.black45,
                                    Colors.transparent,
                                  ],
                                  begin: FractionalOffset(0.0, 0.0),
                                  end: FractionalOffset(1.0, 0.0),
                                  stops: [0.0, 1.0],
                                  tileMode: TileMode.clamp),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    "${widget.users[itemIndex].name}, ${widget.users[itemIndex].editInfo!['showMyAge'] != null ? !widget.users[itemIndex].editInfo!['showMyAge'] ? widget.users[itemIndex].age : "" : widget.users[itemIndex].age}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  widget.users[itemIndex]
                                              .editInfo!['showOnProfile'] ??
                                          false
                                      ? GenderSign(
                                          gender: widget
                                              .users[itemIndex].userGender!,
                                          iconColor: Colors.white,
                                        )
                                      : const SizedBox.shrink()
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  "${widget.users[itemIndex].address}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                  onPressed: () {
                                    LoadAds.loadInterstitialAd(
                                        interstitialAd, isInterstitialAdReady);

                                    interstitialAd?.show();
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return Info(
                                          widget.users[itemIndex],
                                          widget.currentUser,
                                          true,
                                          controller: widget.stackController,
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.arrow_upward,
                                    color: primaryColor,
                                  )),
                            ),
                          ),
                          // Positioned.fill(
                          //   child: Align(
                          //     alignment: Alignment.center,
                          //     child: Container(
                          //       width: 13,
                          //       height: 13,
                          //       decoration: BoxDecoration(
                          //         shape: BoxShape.circle,
                          //         color:
                          //             primaryColor, // Change the color as needed
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            onSwipeCompleted: widget.onswiped,
            controller: widget.stackController,
          );
  }
}
