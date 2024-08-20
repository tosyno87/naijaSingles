// ignore_for_file: unnecessary_string_interpolations, sort_child_properties_last, use_build_context_synchronously

import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u2/common/utlis/custom_toast.dart';
import 'package:hookup4u2/common/widets/custom_snackbar.dart';
import 'package:hookup4u2/features/ads/google_ads.dart';
import 'package:hookup4u2/features/ads/load_ads.dart';
import 'package:hookup4u2/features/chat/ui/widgets/send_message_box.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/calling_repo.dart';
import '../../../../common/data/repo/user_repo.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../match/bloc/match_bloc.dart';
import '../../../report/report_user.dart';

class ChatPage extends StatefulWidget {
  final UserModel sender;
  final String chatId;
  final UserModel second;
  const ChatPage(
      {super.key,
      required this.sender,
      required this.second,
      required this.chatId});
  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  InterstitialAd? interstitialAd;
  bool isInterstitialAdReady = true;
  bool isBlocked = false;
  Timer? debouncer;
  bool isCalling = false; // Flag to track if onJoin is in progress
  final db = firebaseFireStoreInstance;
  late CollectionReference chatReference;
  User currentUser = firebaseAuthInstance.currentUser!;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  // Ads _ads = new Ads();

  @override
  void initState() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('InterstitialAd failed to load: $error');
          },
        ));

    LoadAds.loadInterstitialAd(interstitialAd, isInterstitialAdReady);
    Future.delayed(const Duration(milliseconds: 2000), () {
// Here you can write your code

      if (mounted) {
        (() {
          // Here you can write your code for open new view
          if (isInterstitialAdReady) {
            interstitialAd?.show();
          }
        });
      }
    });

    super.initState();

    chatReference =
        db.collection("chats").doc(widget.chatId).collection('messages');
    checkBlock();
  }

  @override
  void dispose() {
    interstitialAd?.dispose();
    debouncer?.cancel();
    super.dispose();
  }

  void debounce(VoidCallback callback,
      {Duration duration = const Duration(seconds: 15)}) {
    if (!isCalling) {
      // Check if a call is not in progress
      callback(); // Execute the callback immediately
      isCalling =
          true; // Set isCalling to true to indicate a call is in progress
    } else {
      // Cancel any existing debouncer timer to prevent multiple calls
      debouncer?.cancel();
    }
    // Schedule a new timer to reset the isCalling flag after the specified duration
    debouncer = Timer(duration, () {
      isCalling = false; // Reset isCalling after the duration has elapsed
    });
  }

  String? blockedBy;
  checkBlock() {
    chatReference.doc('blocked').snapshots().listen((onData) {
      if (true) {
        // (onData.data != null) {
        blockedBy = onData.get('blockedBy');
        if (onData.get('isBlocked')) {
          isBlocked = true;
        } else {
          isBlocked = false;
        }

        if (mounted) setState(() {});
      }
      // print(onData.data['blockedBy']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            centerTitle: false,
            elevation: 0,
            title: Text(widget.second.name!),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            actions: <Widget>[
              IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    debounce(() async {
                      await CallingRepo.onJoin(
                          "AudioCall",
                          isBlocked,
                          widget.chatId,
                          widget.sender.id,
                          context,
                          widget.second);
                    });

                    // onJoin("AudioCall");
                  }),
              IconButton(
                  icon: const Icon(Icons.video_call),
                  onPressed: () {
                    debounce(() async {
                      await CallingRepo.onJoin(
                          "VideoCall",
                          isBlocked,
                          widget.chatId,
                          widget.sender.id,
                          context,
                          widget.second);
                    });
                  }),
              PopupMenuButton(itemBuilder: (ct) {
                return [
                  PopupMenuItem(
                    value: 'value1',
                    child: InkWell(
                      onTap: () => showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (context) => ReportUser(
                                reported: widget.second,
                                reportedBy: widget.sender,
                              )).then((value) => Navigator.pop(ct)),
                      child: SizedBox(
                          width: 100,
                          height: 30,
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : primaryColor,
                                size: 20,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Report".tr().toString(),
                              ),
                            ],
                          )),
                    ),
                  ),
                  PopupMenuItem(
                    height: 30,
                    value: 'value2',
                    child: InkWell(
                      child: Row(
                        children: [
                          Icon(
                            Icons.block_outlined,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(isBlocked
                              ? "Unblock user".tr().toString()
                              : "Block user".tr().toString()),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ct);
                        showDialog(
                          context: context,
                          builder: (BuildContext ctx) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: AlertDialog(
                                title: Text(isBlocked
                                    ? 'Unblock'.tr().toString()
                                    : 'Block'.tr().toString()),
                                content: Text("Do you want to".tr(args: [
                                  "${isBlocked ? 'Unblock'.tr().toString() : 'Block'.tr().toString()}",
                                  "${widget.second.name}"
                                ])),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text(
                                      'No'.tr().toString(),
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      if (isBlocked &&
                                          blockedBy == widget.sender.id) {
                                        chatReference.doc('blocked').set({
                                          'isBlocked': !isBlocked,
                                          'blockedBy': widget.sender.id,
                                        }, SetOptions(merge: true));
                                        // For deleting from   blocklist
                                        await firebaseFireStoreInstance
                                            .collection("Users")
                                            .doc(widget.sender.id)
                                            .collection("blockedlist")
                                            .doc(widget.second
                                                .id) // Assuming widget.second.id represents the blocked user's ID
                                            .delete();

                                        CustomToast.showToast(
                                            "User Unblocked Successfully"
                                                .tr()
                                                .toString());
                                      } else if (!isBlocked) {
                                        chatReference.doc('blocked').set({
                                          'isBlocked': !isBlocked,
                                          'blockedBy': widget.sender.id,
                                        }, SetOptions(merge: true));
                                        // For adding in   blocklist
                                        await firebaseFireStoreInstance
                                            .collection("Users")
                                            .doc(widget.sender.id)
                                            .collection("blockedlist")
                                            .doc(widget.second
                                                .id) // Generate a unique document ID for each blocked user
                                            .set({
                                          'isBlocked': !isBlocked,
                                          'blockedID': widget.second.id,
                                          'timestamp':
                                              FieldValue.serverTimestamp()
                                        });

                                        CustomToast.showToast(
                                            "User blocked Successfully"
                                                .tr()
                                                .toString());
                                      } else {
                                        CustomSnackbar.showSnackBarSimple(
                                            "You can't unblock".tr().toString(),
                                            context);
                                      }
                                    },
                                    child: Text(
                                      'Yes'.tr().toString(),
                                      style: TextStyle(color: primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  PopupMenuItem(
                    value: 'value3',
                    child: InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (BuildContext ctx) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: AlertDialog(
                              title: Text(
                                'Unmatch'.tr().toString(),
                                style: TextStyle(
                                    fontSize: 18, color: primaryColor),
                              ),
                              content: Text(
                                  "Do you want to unmatch with".tr(args: [
                                    "${widget.second.name}".toString()
                                  ]).toString(),
                                  style: const TextStyle(fontSize: 16)),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'No'.tr().toString(),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await UserRepo.unmatchUser(
                                        widget.sender, widget.second.id!);
                                    context.read<SearchUserBloc>().add(
                                        LoadUserEvent(
                                            currentUser: widget.sender));
                                    context.read<MatchUserBloc>().add(
                                        LoadMatchUserEvent(
                                            currentUser: widget.sender));
                                    CustomSnackbar.showSnackBarSimple(
                                        "unmatched".tr(args: [
                                          "${widget.second.name}".toString()
                                        ]).toString(),
                                        context);
                                    Navigator.pop(context);
                                    // Navigator.pushReplacement(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) => const Tabbar(null, false)));
                                  },
                                  child: Text(
                                    'Yes'.tr().toString(),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).then((value) => Navigator.pop(ct)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : primaryColor,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Unmatch".tr().toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              })
            ]),
        body: MessageBox(
            sender: widget.sender,
            chatId: widget.chatId,
            second: widget.second));
  }
}
