import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/features/calling/ui/screens/call.dart';

import '../../../common/constants/colors.dart';
import '../../../common/constants/constants.dart';
import '../../../common/data/repo/calling_repo.dart';
import '../../../common/widets/image_widget.dart';
import '../../../models/user_model.dart';

class DialCall extends StatefulWidget {
  final String? channelName;
  final UserModel? receiver;
  final String? callType;
  const DialCall(
      {super.key, @required this.channelName, this.receiver, this.callType});

  @override
  DialCallState createState() => DialCallState();
}

class DialCallState extends State<DialCall> {
  bool ispickup = false;
  //final db = Firestore.instance;
  CollectionReference callRef = firebaseFireStoreInstance.collection("calls");
  @override
  void initState() {
    CallingRepo.addCallingData(widget.channelName, widget.callType);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _callingdispose();
  }

  _callingdispose() async {
    ispickup = true;
    await callRef
        .doc(widget.channelName)
        .set({'calling': false}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    log("name ${widget.channelName}");
    // final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
          child: StreamBuilder<QuerySnapshot>(
              stream: callRef
                  .where("channel_id", isEqualTo: "${widget.channelName}")
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container();
                } else {
                  try {
                    switch (snapshot.data?.docs[0]['response']) {
                      case "Awaiting":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              CircleAvatar(
                                backgroundColor: Colors.grey,
                                radius: 60,
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      60,
                                    ),
                                    child: CustomCNImage(
                                      imageUrl:
                                          widget.receiver?.imageUrl?.first ??
                                              '',
                                      main: true,
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                  "Calling to ${widget.receiver?.name}..."
                                      .tr()
                                      .toString(),
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                  // color: AppColors.primaryColor,
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              primaryColor)),
                                  icon: const Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "END",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    await callRef.doc(widget.channelName).set(
                                        {'response': "Call_Cancelled"},
                                        SetOptions(merge: true));
                                    // Navigator.pop(context);
                                  })
                            ],
                          );
                        }

                      case "Pickup":
                        ispickup = true;
                        return CallPage(
                            channelName: widget.channelName!,
                            role: ClientRoleType.clientRoleBroadcaster,
                            callType: widget.callType!);

                      case "Decline":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text("${widget.receiver!.name} is Busy",
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                  // color: AppColors.primaryColor,
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              primaryColor)),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Back",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  })
                            ],
                          );
                        }
                      // break;
                      case "Not-answer":
                        {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text("${widget.receiver!.name} is not answering",
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                  // color: AppColors.primaryColor,
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              primaryColor)),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    "Back",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  })
                            ],
                          );
                        }
                      // break;
                      //call end
                      default:
                        {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            Navigator.pop(context);
                          });
                          return const Text("Call Ended...");
                        }
                      // break;
                    }
                  }
                  //  else if (!snapshot.data.documents[0]['calling']) {
                  //   Navigator.pop(context);
                  // }
                  catch (e) {
                    rethrow;
                  }
                }
              })),
    );
  }
}
