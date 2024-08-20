import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/user_model.dart';
import '../screens/chat_page.dart';

class SingleChatTile extends StatelessWidget {
  final UserModel tempUser;
  final ChatModel chat;
  final String chatId;
  final UserModel currentUser;

  const SingleChatTile({
    Key? key,
    required this.chat,
    required this.chatId,
    required this.tempUser,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final db = firebaseFireStoreInstance;
    final chatReference =
        db.collection("chats").doc(chatId).collection('messages');
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin:
          const EdgeInsets.only(top: 5.0, bottom: 5.0, right: 10.0, left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: chat.senderId != currentUser.id && !chat.isRead
            ? themeProvider.isDarkMode
                ? Theme.of(context).scaffoldBackgroundColor
                : primaryColor.withOpacity(.1)
            : themeProvider.isDarkMode
                ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.60)
                : secondryColor.withOpacity(.2),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20.0),
          topLeft: Radius.circular(20.0),
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black54,
          radius: 30.0,
          backgroundImage: NetworkImage(tempUser.imageUrl!.first ?? ""),
        ),
        title: Text(
          tempUser.name!,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: StreamBuilder<DocumentSnapshot>(
          stream: chatReference.doc('blocked').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final blockedBy = snapshot.data!.get('blockedBy');
              final isBlocked = snapshot.data!.get('isBlocked');

              return !isBlocked
                  ? Text(
                      chat.type == 'Image'
                          ? "Photo"
                          : chat.text!.replaceAll('\n', ' '),
                      style: TextStyle(
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.blueGrey,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  : blockedBy == currentUser.id
                      ? Text(
                          "You blocked this contact".tr().toString(),
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.blueGrey,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          "This contact has blocked you".tr().toString(),
                          style: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.blueGrey,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
            }

            return const SizedBox.shrink();
          },
        ),
        trailing: StreamBuilder<DocumentSnapshot>(
          stream: chatReference.doc('blocked').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final isBlocked = snapshot.data!.get('isBlocked');

              return !isBlocked
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          chat.timestamp != null
                              ? DateFormat('dd/MM/yy')
                                  .format(chat.timestamp!.toDate())
                                  .toString()
                              : "",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        chat.senderId != currentUser.id && !chat.isRead
                            ? Container(
                                width: 45.0,
                                height: 18.0,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'NEW'.tr().toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const Text(""),
                        chat.senderId == currentUser.id
                            ? !chat.isRead
                                ? Icon(
                                    Icons.done,
                                    color: secondryColor,
                                    size: 15,
                                  )
                                : Icon(
                                    Icons.done_all,
                                    color: primaryColor,
                                    size: 15,
                                  )
                            : const Text(""),
                      ],
                    )
                  : const SizedBox.shrink();
            }

            return const SizedBox.shrink();
          },
        ),
        onTap: () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                sender: currentUser,
                second: tempUser,
                chatId: chatId,
              ),
            ),
          );
        },
      ),
    );
  }
}
