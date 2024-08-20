// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/features/calling/ui/screens/call.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';

class Incoming extends StatefulWidget {
  final callInfo;
  const Incoming(this.callInfo, {super.key});

  @override
  IncomingState createState() => IncomingState();
}

class IncomingState extends State<Incoming> with TickerProviderStateMixin {
  CollectionReference callRef = firebaseFireStoreInstance.collection("calls");

  bool ispickup = false;
  late AnimationController _controller;

  @override
  void initState() {
    log('incoming call called~~~~~~~~~~~~~~~~~~~~');
    super.initState();
    // FlutterRingtonePlayer.play(
    //   android: AndroidSounds.ringtone,
    //   ios: IosSounds.glass,
    //   looping: true, // Android only - API >= 28
    //   volume: 1, // Android only - API >= 28
    //   asAlarm: false, // Android only - all APIs
    // );
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() async {
    _controller.dispose();
    // await FlutterRingtonePlayer.stop();
    ispickup = true;

    await callRef.doc(widget.callInfo['channel_id']).update({'calling': false});
    log('-------------incoming dispose-----------');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          // appBar: AppBar(
          //   centerTitle: true,
          //   elevation: 0,
          //   backgroundColor: Colors.white,
          //   title: Text(
          //     "Incoming Call",
          //     style: TextStyle(color: Colors.red),
          //   ),
          // ),
          body: Center(
            child: StreamBuilder<QuerySnapshot>(
              stream: callRef
                  .where("channel_id",
                      isEqualTo: "${widget.callInfo['channel_id']}")
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                // Future.delayed(Duration(seconds: 30), () async {
                //   if (!ispickup) {
                //     await callRef
                //         .doc(widget.callInfo['channel_id'])
                //         .update({'response': 'Not-answer'});
                //   }
                //   Navigator.pop(context);
                // });
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container();
                } else {
                  try {
                    if (snapshot.data!.docs[0]['response'] == 'Awaiting') {
                      log('snapshot values are ${snapshot.data!.docs[0]['response']}');

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            snapshot.data!.docs[0]['callType'] == "VideoCall"
                                ? "Incoming Video Call".tr().toString()
                                : "Incoming Audio Call".tr().toString(),
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 25,
                                fontWeight: FontWeight.bold),
                          ),
                          AnimatedBuilder(
                              animation: CurvedAnimation(
                                  parent: _controller,
                                  curve: Curves.slowMiddle),
                              builder: (context, child) {
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * .3,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      _buildContainer(150 * _controller.value),
                                      _buildContainer(200 * _controller.value),
                                      _buildContainer(250 * _controller.value),
                                      _buildContainer(300 * _controller.value),
                                      //_buildContainer(350 * _controller.value),
                                      // Align(
                                      //     child: Icon(
                                      //   Icons.phone_android,
                                      //   size: 44,
                                      // )),

                                      CircleAvatar(
                                        backgroundColor: Colors.grey,
                                        radius: 60,
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              60,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: widget.callInfo[
                                                      'senderPicture'] ??
                                                  '',
                                              useOldImageOnUrlChange: true,
                                              placeholder: (context, url) =>
                                                  const CupertinoActivityIndicator(
                                                radius: 15,
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: <Widget>[
                                                  const Icon(
                                                    Icons.error,
                                                    color: Colors.black,
                                                    size: 30,
                                                  ),
                                                  Text(
                                                    "Unable to load"
                                                        .tr()
                                                        .toString(),
                                                    style: const TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "${widget.callInfo['senderName']} ",
                                style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                              Shimmer.fromColors(
                                baseColor: Colors.white,
                                highlightColor: Colors.black,
                                child: Text(
                                  "is calling you...".tr().toString(),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                FloatingActionButton(
                                    heroTag: UniqueKey(),
                                    backgroundColor: Colors.green,
                                    child: Icon(
                                      snapshot.data!.docs[0]['callType'] ==
                                              "VideoCall"
                                          ? Icons.video_call
                                          : Icons.call,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      ispickup = true;

                                      await callRef
                                          .doc(widget.callInfo['channel_id'])
                                          .update({'response': "Pickup"});
                                      // await FlutterRingtonePlayer.stop();
                                    }),
                                FloatingActionButton(
                                    heroTag: UniqueKey(),
                                    backgroundColor: Colors.red,
                                    child: const Icon(Icons.clear,
                                        color: Colors.white),
                                    onPressed: () async {
                                      await callRef
                                          .doc(widget.callInfo['channel_id'])
                                          .update({'response': 'Decline'});

                                      log('decilne incoming dart------------------------------------');
                                      Future.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                        Navigator.pop(context);
                                      });
                                    })
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    //    break;
                    // push video page with given channel name
                    //    case "Pickup":
                    else if (snapshot.data!.docs[0]['response'] == 'Pickup') {
                      log("call is picked up ${widget.callInfo['channel_id']} , callType ${snapshot.data!.docs[0]['callType']}");
                      return CallPage(
                        channelName: widget.callInfo['channel_id'],
                        role: ClientRoleType.clientRoleBroadcaster,
                        callType: snapshot.data!.docs[0]['callType'],
                      );
                    }

                    //call end
                    else if ((snapshot.data!.docs[0]['response'] ==
                        "Call_Cancelled"))

                    //       'Pickup' ||
                    //   snapshot.data!.docs[0]['response'] == 'Awaiting'))
                    {
                      log('call ended ${snapshot.data!.docs[0]['response']}');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        Navigator.pop(context);
                      });
                      return Text("Call Ended...".tr().toString());
                    }
                    //   }
                    // else if (snapshot.data!.docs[0]['response'] ==
                    //     "Call_Cancelled") {
                    //   return Container(
                    //     child: Text("Missed call"),
                    //   );
                    // }
                    else if (snapshot.data!.docs[0]['response'] == "Decline") {
                      //FlutterRingtonePlayer.stop();

                      log('decilne ------------------------------------');
                      return const Text("Decline call");
                    } else {
                      log('default is log');
                      Future.delayed(const Duration(milliseconds: 500), () {
                        Navigator.pop(context);
                      });
                      return Text("Call Ended...".tr().toString());
                    }
                  } catch (e) {
                    log('errrrrrrrrrrrrrr $e');
                    return Container();
                  }
                }

                // return Container(
                //   child: InkWell(
                //     child: Text('Call has ended \n Tap here'),
                //     onTap: () {
                //       Navigator.pop(context);
                //     },
                //   ),
                // );
              },
            ),
          ),
        ));
  }

  Widget _buildContainer(double radius) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(1 - _controller.value),
      ),
    );
  }
}
