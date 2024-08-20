import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/common/widets/hookup_circularbar.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/image_widget.dart';
import '../../../chat/ui/screens/chat_page.dart';
import '../../bloc/match_bloc.dart';

class Matches extends StatefulWidget {
  final UserModel currentUser;
  const Matches({super.key, required this.currentUser});

  @override
  State<Matches> createState() => _MatchesState();
}

class _MatchesState extends State<Matches> {
  @override
  void initState() {
    context
        .read<MatchUserBloc>()
        .add(LoadMatchUserEvent(currentUser: widget.currentUser));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'New Matches'.tr().toString(),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_outlined,
                  ),
                  iconSize: 24.0,
                  color: Colors.red,
                  onPressed: () {
                    context.read<MatchUserBloc>().add(
                        LoadMatchUserEvent(currentUser: widget.currentUser));
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<MatchUserBloc, MatchUserState>(
            builder: (context, state) {
              if (state is MatchUserLoadingState) {
                log("i am in matchuserloading");
                return const Hookup4uBar();
              }
              if (state is MatchUserFailedState) {
                log("I AM IN LOADUSERSFailed");
                return Center(
                    child: Text(
                  "Error to load data.".tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black54,
                      fontStyle: FontStyle.normal,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                      fontSize: 18),
                ));
              }
              if (state is MatchUserLoadedState) {
                log("i am in matchusersuccess");
                return SizedBox(
                    height: size.height * 0.18,
                    child: state.users.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.only(left: 10.0),
                            scrollDirection: Axis.horizontal,
                            itemCount: state.users.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                              chatId: chatId(widget.currentUser,
                                                  state.users[index]),
                                              sender: widget.currentUser,
                                              second: state.users[index],
                                            ))),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.all(1.5),
                                        height: size.height * 0.11,
                                        width: size.width * 0.19,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                                style: BorderStyle.solid,
                                                width: 2,
                                                color: primaryColor)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          child: CustomCNImage(
                                            imageUrl: state.users[index]
                                                    .imageUrl![0] ??
                                                '',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6.0),
                                      SizedBox(
                                        width: size.width * 0.19,
                                        child: Text(
                                          state.users[index].name!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: secondryColor,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                            "No match found".tr().toString(),
                            style:
                                TextStyle(color: secondryColor, fontSize: 16),
                          )));
              }
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                    child: Text(
                  "No match found".tr().toString(),
                  style: TextStyle(color: secondryColor, fontSize: 16),
                )),
              );
            },
          ),
        ],
      ),
    );
  }
}

String chatId(currentUser, sender) {
  if (currentUser.id.hashCode <= sender.id.hashCode) {
    return '${currentUser.id}-${sender.id}';
  } else {
    return '${sender.id}-${currentUser.id}';
  }
}
