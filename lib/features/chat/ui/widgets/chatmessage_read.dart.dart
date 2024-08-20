import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hookup4u2/common/widets/image_widget.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utlis/custom_toast.dart';
import '../../../user/ui/widgets/user_info.dart';

class ChatMessageRead {
  static messagesIsRead(
      documentSnapshot, UserModel second, sender, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: CircleAvatar(
                backgroundColor: secondryColor,
                radius: 25.0,
                backgroundImage: NetworkImage(second.imageUrl![0] ?? ''),
              ),
            ),
            onTap: () => showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return Info(
                    second,
                    sender,
                    false,
                    fromChatPage: true,
                  );
                }),
          ),
        ],
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              child: documentSnapshot.data()!['image_url'] != ''
                  ? InkWell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.only(
                                top: 2.0, bottom: 2.0, right: 15),
                            height: 150,
                            width: 150.0,
                            color: const Color.fromRGBO(0, 0, 0, 0.2),
                            padding: const EdgeInsets.all(5),
                            child: CustomCNImage(
                              height: MediaQuery.of(context).size.height * .65,
                              width: MediaQuery.of(context).size.width * .9,
                              imageUrl:
                                  documentSnapshot.data()!['image_url'] ?? '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Text(
                                documentSnapshot.data()!["time"] != null
                                    ? DateFormat.yMMMd('en_US')
                                        .add_jm()
                                        .format(documentSnapshot
                                            .data()!["time"]
                                            .toDate())
                                        .toString()
                                    : "",
                                style: TextStyle(
                                  color: secondryColor,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                )),
                          )
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, RouteName.largeImageScreen,
                            arguments: documentSnapshot.get('image_url'));
                      },
                    )
                  : GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(
                            text: documentSnapshot.data()!['text']));
                        CustomToast.showToast('Message Copied'.tr().toString());
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 10.0),
                          width: MediaQuery.of(context).size.width * 0.65,
                          margin: const EdgeInsets.only(
                              top: 8.0, bottom: 8.0, right: 10),
                          decoration: BoxDecoration(
                              color: secondryColor.withOpacity(.3),
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                documentSnapshot.data()!['text'],
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    documentSnapshot.data()!["time"] != null
                                        ? DateFormat.MMMd('en_US')
                                            .add_jm()
                                            .format(documentSnapshot
                                                .data()!["time"]
                                                .toDate())
                                            .toString()
                                        : "",
                                    style: TextStyle(
                                      color: secondryColor,
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )),
                    ),
            ),
          ],
        ),
      ),
    ];
  }
}
