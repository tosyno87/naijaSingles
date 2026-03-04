import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../common/widgets/hookup_circularbar.dart';
import '../../../match/ui/widget/matches_card.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/data/repo/pagination_repo.dart';
import '../../../../common/data/repo/user_messaging_repo.dart';
import '../../../../common/utils/custom_toast.dart';
import '../../../../config/app_config.dart';
import '../../../../config/prompt_config.dart';
import '../../../../models/user_model.dart';
import 'chatmessage_read.dart.dart';
import 'generate_layout.dart';

bool shouldUploadImage(XFile? image) => image != null;

class MessageBox extends StatefulWidget {
  const MessageBox({
    required this.sender,
    required this.chatId,
    required this.second,
    super.key,
  });
  final UserModel sender;
  final String chatId;
  final UserModel second;

  @override
  State<MessageBox> createState() => _MessageBoxState();
}

class _MessageBoxState extends State<MessageBox> {
  bool isBlocked = false;
  final int perpage = perPageData;
  final db = firebaseFireStoreInstance;
  final List<String> prompts = chatPrompts;
  late CollectionReference chatReference;
  final TextEditingController _textController = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _blockSubscription;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  bool _isWritting = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  late DocumentSnapshot? lastVisibleDocument;
  late List<QueryDocumentSnapshot> messages = [];

  final ScrollController _scrollController = ScrollController();

  List<Widget> generateSenderLayout(DocumentSnapshot documentSnapshot) =>
      <Widget>[
        Expanded(child: Layout(documentSnapshot: documentSnapshot)),
      ];

  List<Widget> generateReceiverLayout(DocumentSnapshot documentSnapshot) {
    if (!documentSnapshot.get('isRead')) {
      chatReference.doc(documentSnapshot.id).update({
        'isRead': true,
      });
      db.collection('chats').doc(chatId(widget.second, widget.sender)).update({
        'isRead': true,
      });
      return ChatMessageRead.messagesIsRead(
        documentSnapshot,
        widget.second,
        widget.sender,
        context,
      );
    }
    return ChatMessageRead.messagesIsRead(
      documentSnapshot,
      widget.second,
      widget.sender,
      context,
    );
  }

  @override
  void initState() {
    super.initState();

    chatReference =
        db.collection('chats').doc(widget.chatId).collection('messages');
    checkBlock();
    _scrollController.addListener(_scrollListener);
    _loadInitialMessages();
  }

  String? blockedBy;
  void checkBlock() {
    _blockSubscription = chatReference.doc('blocked').snapshots().listen((onData) {
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
    _blockSubscription?.cancel();
    _messageSubscription?.cancel();
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
    final Stream<QuerySnapshot> snapshotStream =
        PaginationRepo.listenForMessages(perpage, chatReference);
    _messageSubscription = snapshotStream.listen((snapshot) {
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

  Future<void> _loadMoreMessages() async {
    setState(() {
      _isLoadingMore = true;
    });
    final snapshot = await PaginationRepo.getMoreMessages(
      perpage,
      lastVisibleDocument,
      chatReference,
    );
    setState(() {
      messages.addAll(snapshot.docs);
      _hasMoreMessages = snapshot.docs.length == perpage;
      _isLoadingMore = false;
      lastVisibleDocument =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    });
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).primaryColor,
          body: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
                color: Theme.of(context).primaryColor,
              ),
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
                                    child: Hookup4uBar(),
                                  ),
                              ],
                            );
                          } else {
                            return generateMessages(documentSnapshot);
                          }
                        },
                      ),
                    ),
                    if (messages.isEmpty && !isBlocked)
                      _buildPromptSuggestions(),
                    const Divider(height: 1),
                    Container(
                      alignment: Alignment.bottomCenter,
                      decoration:
                          const BoxDecoration(color: Colors.transparent),
                      child: isBlocked
                          ? blockedBy == widget.sender.id
                              ? Text('you blocked this user!'.tr().toString())
                              : Text(
                                  '${widget.second.name} blocked you!'
                                      .tr()
                                      .toString(),
                                )
                          : _buildTextComposer(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Container generateMessages(QueryDocumentSnapshot<Object?> snapshot) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: snapshot.get('type') == 'Call'
              ? [
                  Text(
                    snapshot.get('time') != null
                        ? "${snapshot.get('text')} : ${DateFormat.yMMMd('en_US').add_jm().format(snapshot.get('time').toDate())} by ${snapshot.get('sender_id') == widget.sender.id ? "You" : "${widget.second.name}"}"
                        : '',
                  ),
                ]
              : snapshot.get('sender_id') != widget.sender.id
                  ? generateReceiverLayout(snapshot)
                  : generateSenderLayout(snapshot),
        ),
      );

  Widget _buildPromptSuggestions() => Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: prompts
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(p),
                      onPressed: () {
                        _sendText(p);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );

  Widget _buildTextComposer() => IconTheme(
        data: IconThemeData(
          color: _isWritting ? AppColors.primaryGreen : AppColors.secondaryColor,
        ),
        child: Card(
          elevation: 10,
          margin: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: Border.all(color: AppColors.secondaryColor),
              borderRadius: BorderRadius.circular(40),
            ),
            margin: const EdgeInsets.symmetric(),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: const Icon(
                    Icons.photo_camera,
                    color: AppColors.primaryGreen,
                  ),
                  onPressed: () async {
                    final ImagePicker imagePicker = ImagePicker();

                    final picked = await imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked == null) return;

                    final int timestamp = DateTime.now().millisecondsSinceEpoch;
                    final Reference storageReference = FirebaseStorage.instance
                        .ref()
                        .child('chats/${widget.chatId}/img_$timestamp.jpg');
                    final UploadTask uploadTask =
                        storageReference.putFile(File(picked.path));
                    CustomToast.showToast('sending...'.tr().toString());
                    await uploadTask.then((p0) async {
                      final String fileUrl =
                          await storageReference.getDownloadURL();
                      await UserMessagingRepo.sendImage(
                        'photo',
                        fileUrl,
                        chatReference,
                        widget.chatId,
                        widget.sender.id,
                        widget.second.id,
                      );

                      CustomToast.showToast('sent');
                    });
                  },
                ),
                Flexible(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: TextField(
                      controller: _textController,
                      maxLines: 4,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      onChanged: (String messageText) {
                        setState(() {
                          _isWritting = messageText.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration.collapsed(
                        hintStyle: const TextStyle(color: Colors.grey),
                        hintText: 'Send a message...'.tr().toString(),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: getDefaultSendButton(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget getDefaultSendButton() => IconButton(
        icon: Transform.rotate(
          angle: -pi / 9,
          child: const Icon(
            Icons.send,
            size: 25,
          ),
        ),
        color: AppColors.primaryGreen,
        onPressed: _isWritting
            ? () => _sendText(_textController.text.trimRight())
            : null,
      );

  Future _sendText(String text) async {
    _textController.clear();
    await UserMessagingRepo.addTexttoDb(
      chatReference,
      text,
      widget.chatId,
      widget.sender.id!,
      widget.second.id,
    );
    setState(() {
      _isWritting = false;
    });
  }
}
