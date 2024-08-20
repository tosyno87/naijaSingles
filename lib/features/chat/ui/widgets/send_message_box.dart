// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/widets/hookup_circularbar.dart';
import 'package:hookup4u2/features/match/ui/widget/matches_card.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/pagination_repo.dart';
import '../../../../common/data/repo/user_messaging_repo.dart';
import '../../../../common/utlis/custom_toast.dart';
import '../../../../config/app_config.dart';
import '../../../../models/user_model.dart';
import 'chatmessage_read.dart.dart';
import 'generate_layout.dart';

class MessageBox extends StatefulWidget {
  final UserModel sender;
  final String chatId;
  final UserModel second;
  const MessageBox(
      {super.key,
      required this.sender,
      required this.chatId,
      required this.second});

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> {
  bool isBlocked = false;
  final int perpage = perPageData;
  final db = firebaseFireStoreInstance;
  late CollectionReference chatReference;
  final TextEditingController _textController = TextEditingController();
  bool _isWritting = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  late DocumentSnapshot? lastVisibleDocument;
  late List<QueryDocumentSnapshot> messages = [];

  final ScrollController _scrollController = ScrollController();

  List<Widget> generateSenderLayout(DocumentSnapshot documentSnapshot) {
    return <Widget>[
      Expanded(child: Layout(documentSnapshot: documentSnapshot)),
    ];
  }

  List<Widget> generateReceiverLayout(DocumentSnapshot documentSnapshot) {
    if (!documentSnapshot.get('isRead')) {
      chatReference.doc(documentSnapshot.id).update({
        'isRead': true,
      });
      db.collection('chats').doc(chatId(widget.second, widget.sender)).update({
        'isRead': true,
      });
      return ChatMessageRead.messagesIsRead(
          documentSnapshot, widget.second, widget.sender, context);
    }
    return ChatMessageRead.messagesIsRead(
        documentSnapshot, widget.second, widget.sender, context);
  }

  @override
  void initState() {
    super.initState();

    chatReference =
        db.collection("chats").doc(widget.chatId).collection('messages');
    checkBlock();
    _scrollController.addListener(_scrollListener);
    _loadInitialMessages();
  }

  var blockedBy;
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
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_scrollController.position.outOfRange) {
      if (_hasMoreMessages && !_isLoadingMore) {
        _loadMoreMessages();
      }
    }
  }

  void _loadInitialMessages() {
    Stream<QuerySnapshot> snapshotStream =
        PaginationRepo.listenForMessages(perpage, chatReference);
    snapshotStream.listen((snapshot) {
      if (mounted) {
        setState(() {
          messages = snapshot.docs;
          _hasMoreMessages = snapshot.docs.length == perpage;
          _isLoadingMore = false;
          lastVisibleDocument =
              snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        });
      }
    });
  }

  void _loadMoreMessages() async {
    setState(() {
      _isLoadingMore = true;
    });
    final snapshot = await PaginationRepo.getMoreMessages(
        perpage, lastVisibleDocument, chatReference);
    setState(() {
      messages.addAll(snapshot.docs);
      _hasMoreMessages = snapshot.docs.length == perpage;
      _isLoadingMore = false;
      lastVisibleDocument =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50.0),
            topRight: Radius.circular(50.0),
          ),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50)),
                color: Theme.of(context).primaryColor),
            padding: const EdgeInsets.all(5),
            child: CupertinoScrollbar(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final documentSnapshot = messages[index];
                        if (index == messages.length - 1) {
                          return Column(
                            children: [
                              generateMessages(documentSnapshot),
                              if (_isLoadingMore)
                                const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Hookup4uBar()),
                            ],
                          );
                        } else {
                          return generateMessages(documentSnapshot);
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1.0),
                  Container(
                    alignment: Alignment.bottomCenter,
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: isBlocked
                        ? blockedBy == widget.sender.id
                            ? Text("you blocked this user!".tr().toString())
                            : Text("${widget.second.name} blocked you!"
                                .tr()
                                .toString())
                        : _buildTextComposer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  generateMessages(QueryDocumentSnapshot<Object?> snapshot) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: snapshot.get('type') == "Call"
            ? [
                Text(snapshot.get('time') != null
                    ? "${snapshot.get('text')} : ${DateFormat.yMMMd('en_US').add_jm().format(snapshot.get('time').toDate())} by ${snapshot.get('sender_id') == widget.sender.id ? "You" : "${widget.second.name}"}"
                    : "")
              ]
            : snapshot.get('sender_id') != widget.sender.id
                ? generateReceiverLayout(snapshot)
                : generateSenderLayout(snapshot),
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: _isWritting ? primaryColor : secondryColor),
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                border: Border.all(color: secondryColor, width: 1),
                borderRadius: BorderRadius.circular(40)),
            margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                IconButton(
                    icon: Icon(
                      Icons.photo_camera,
                      color: primaryColor,
                    ),
                    onPressed: () async {
                      ImagePicker imagePicker = ImagePicker();

                      var image = await imagePicker.pickImage(
                          source: ImageSource.gallery);
                      int timestamp = DateTime.now().millisecondsSinceEpoch;
                      Reference storageReference = FirebaseStorage.instance
                          .ref()
                          .child('chats/${widget.chatId}/img_$timestamp.jpg');
                      UploadTask uploadTask =
                          storageReference.putFile(File(image!.path));
                      CustomToast.showToast('sending...'.tr().toString());
                      await uploadTask.then((p0) async {
                        String fileUrl =
                            await storageReference.getDownloadURL();
                        UserMessagingRepo.sendImage(
                            'photo',
                            fileUrl,
                            chatReference,
                            widget.chatId,
                            widget.sender.id,
                            widget.second.id);

                        CustomToast.showToast('sent');
                      });
                    }),
                Flexible(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 1,
                      autofocus: false,
                      keyboardType: TextInputType.multiline,
                      onChanged: (String messageText) {
                        setState(() {
                          _isWritting = messageText.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration.collapsed(
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          hintStyle: const TextStyle(color: Colors.grey),
                          hintText: "Send a message...".tr().toString()),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: getDefaultSendButton(),
                ),
              ],
            ),
          ),
        ));
  }

  Widget getDefaultSendButton() {
    return IconButton(
      icon: Transform.rotate(
        angle: -pi / 9,
        child: const Icon(
          Icons.send,
          size: 25,
        ),
      ),
      color: primaryColor,
      onPressed: _isWritting
          ? () => _sendText(_textController.text.trimRight())
          : null,
    );
  }

  Future _sendText(String text) async {
    _textController.clear();
    UserMessagingRepo.addTexttoDb(chatReference, text, widget.chatId,
        widget.sender.id!, widget.second.id);
    setState(() {
      _isWritting = false;
    });
  }
}
