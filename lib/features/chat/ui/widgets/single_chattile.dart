import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../models/chat_model.dart';
import '../../../../models/user_model.dart';
import '../screens/chat_page.dart';

class SingleChatTile extends StatelessWidget {
  const SingleChatTile({
    required this.chat,
    required this.chatId,
    required this.tempUser,
    required this.currentUser,
    super.key,
  });
  final UserModel tempUser;
  final ChatModel chat;
  final String chatId;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    final db = firebaseFireStoreInstance;
    final chatReference =
        db.collection('chats').doc(chatId).collection('messages');
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: chat.senderId != currentUser.id && !chat.isRead
            ? isDarkMode
                ? Theme.of(context).scaffoldBackgroundColor
                : primaryColor.withValues(alpha: (.1 * 255).toDouble())
            : isDarkMode
                ? Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: (0.60 * 255).toDouble())
                : AppColors.secondaryColor
                    .withValues(alpha: (.2 * 255).toDouble()),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black54,
          radius: 30,
          backgroundImage: NetworkImage(tempUser.imageUrl!.first ?? ''),
        ),
        title: Text(
          tempUser.name!,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
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
                          ? 'Photo'
                          : chat.text!.replaceAll('\n', ' '),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white
                            : Colors.blueGrey,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  : blockedBy == currentUser.id
                      ? Text(
                          'You blocked this contact'.tr().toString(),
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Colors.blueGrey,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'This contact has blocked you'.tr().toString(),
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : Colors.blueGrey,
                            fontSize: 15,
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
                              : '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (chat.senderId != currentUser.id && !chat.isRead)
                          Container(
                            width: 45,
                            height: 18,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'NEW'.tr().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const Text(''),
                        if (chat.senderId == currentUser.id)
                          !chat.isRead
                              ? const Icon(
                                  Icons.done,
                                  color: AppColors.secondaryColor,
                                  size: 15,
                                )
                              : const Icon(
                                  Icons.done_all,
                                  color: primaryColor,
                                  size: 15,
                                )
                        else
                          const Text(''),
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
