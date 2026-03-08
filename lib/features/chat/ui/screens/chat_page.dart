import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/constants.dart';
// Calling functionality temporarily disabled
// // Calling functionality removed
import '../../../../common/data/repo/user_repo.dart';
import '../../../../common/utils/custom_toast.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../match/bloc/match_user_bloc.dart';
import '../../../report/report_user.dart';
import '../widgets/send_message_box.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.sender,
    required this.second,
    required this.chatId,
    super.key,
  });
  final UserModel sender;
  final String chatId;
  final UserModel second;
  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  bool isBlocked = false;
  Timer? debouncer;
  bool isCalling = false; // Flag to track if onJoin is in progress
  final db = firebaseFireStoreInstance;
  late CollectionReference chatReference;
  User currentUser = firebaseAuthInstance.currentUser!;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<DocumentSnapshot>? _blockSubscription;

  @override
  void initState() {
    super.initState();

    chatReference =
        db.collection('chats').doc(widget.chatId).collection('messages');
    checkBlock();
  }

  @override
  void dispose() {
    debouncer?.cancel();
    unawaited(_blockSubscription?.cancel());
    super.dispose();
  }

  void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(seconds: 15),
  }) {
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
  void checkBlock() {
    _blockSubscription =
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
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
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
          PopupMenuButton(
            itemBuilder: (ct) => [
              PopupMenuItem(
                value: 'value1',
                child: InkWell(
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => ReportUser(
                        reported: widget.second,
                        reportedBy: widget.sender,
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(ct);
                  },
                  child: SizedBox(
                    width: 100,
                    height: 30,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: isDarkMode
                              ? Colors.white
                              : AppColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          'Report'.tr().toString(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuItem(
                height: 30,
                value: 'value2',
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ct);
                    unawaited(
                      showDialog(
                        context: context,
                        builder: (BuildContext ctx) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AlertDialog(
                            title: Text(
                              isBlocked
                                  ? 'Unblock'.tr().toString()
                                  : 'Block'.tr().toString(),
                            ),
                            content: Text(
                              'Do you want to'.tr(
                                args: [
                                  if (isBlocked)
                                    'Unblock'.tr().toString()
                                  else
                                    'Block'.tr().toString(),
                                  widget.second.name ?? '',
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(
                                  'No'.tr().toString(),
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  if (isBlocked &&
                                      blockedBy == widget.sender.id) {
                                    await chatReference.doc('blocked').set(
                                      {
                                        'isBlocked': !isBlocked,
                                        'blockedBy': widget.sender.id,
                                      },
                                      SetOptions(merge: true),
                                    );
                                    // For deleting from   blocklist
                                    await firebaseFireStoreInstance
                                        .collection('users')
                                        .doc(widget.sender.id)
                                        .collection('blockedlist')
                                        .doc(
                                          widget.second.id,
                                        ) // Assuming widget.second.id represents the blocked user's ID
                                        .delete();

                                    CustomToast.showToast(
                                      'User Unblocked Successfully'
                                          .tr()
                                          .toString(),
                                    );
                                  } else if (!isBlocked) {
                                    await chatReference.doc('blocked').set(
                                      {
                                        'isBlocked': !isBlocked,
                                        'blockedBy': widget.sender.id,
                                      },
                                      SetOptions(merge: true),
                                    );
                                    // For adding in   blocklist
                                    await firebaseFireStoreInstance
                                        .collection('users')
                                        .doc(widget.sender.id)
                                        .collection('blockedlist')
                                        .doc(
                                          widget.second.id,
                                        ) // Generate a unique document ID for each blocked user
                                        .set({
                                      'isBlocked': !isBlocked,
                                      'blockedID': widget.second.id,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    CustomToast.showToast(
                                      'User blocked Successfully'
                                          .tr()
                                          .toString(),
                                    );
                                  } else {
                                    CustomSnackbar.showSnackBarSimple(
                                      "You can't unblock".tr().toString(),
                                      context,
                                    );
                                  }
                                },
                                child: Text(
                                  'Yes'.tr().toString(),
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_outlined,
                        color:
                            isDarkMode ? Colors.white : AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        isBlocked
                            ? 'Unblock user'.tr().toString()
                            : 'Block user'.tr().toString(),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'value3',
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (BuildContext ctx) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: AlertDialog(
                        title: Text(
                          'Unmatch'.tr().toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        content: Text(
                          'Do you want to unmatch with'.tr(
                            args: [
                              widget.second.name ?? '',
                            ],
                          ).toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'No'.tr().toString(),
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await UserRepo.unmatchUser(
                                widget.sender,
                                widget.second.id!,
                              );
                              if (!context.mounted) return;
                              context.read<SearchUserBloc>().add(
                                    LoadUserEvent(
                                      currentUser: widget.sender,
                                    ),
                                  );
                              context.read<MatchUserBloc>().add(
                                    LoadMatchUserEvent(
                                      currentUser: widget.sender,
                                    ),
                                  );
                              CustomSnackbar.showSnackBarSimple(
                                'unmatched'.tr(
                                  args: [
                                    widget.second.name ?? '',
                                  ],
                                ).toString(),
                                context,
                              );
                              Navigator.pop(context);
                              // Navigator.pushReplacement(
                              //     context,
                              //     MaterialPageRoute(
                              //         builder: (context) => const Tabbar(null, false)));
                            },
                            child: Text(
                              'Yes'.tr().toString(),
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).then((value) {
                    if (!context.mounted) return;
                    Navigator.pop(ct);
                  }),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color:
                            isDarkMode ? Colors.white : AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Unmatch'.tr().toString(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: MessageBox(
        sender: widget.sender,
        chatId: widget.chatId,
        second: widget.second,
      ),
    );
  }
}
