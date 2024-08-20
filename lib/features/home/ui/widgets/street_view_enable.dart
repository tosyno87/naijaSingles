import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/providers/street_view_provider.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../match/bloc/match_bloc.dart';

class StreetViewButtonWigdet extends StatefulWidget {
  final UserModel currentUser;
  const StreetViewButtonWigdet({super.key, required this.currentUser});

  @override
  State<StreetViewButtonWigdet> createState() => _StreetViewButtonWigdetState();
}

class _StreetViewButtonWigdetState extends State<StreetViewButtonWigdet> {
  List<UserModel> matchedUsers = [];
  List<String> userIds = [];
  List<String> selectedUserIds = [];
  bool showUserList = false;

  @override
  void initState() {
    context
        .read<MatchUserBloc>()
        .add(LoadMatchUserEvent(currentUser: widget.currentUser));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final streetviewProvider = Provider.of<StreetViewProvider>(context);
    String selectedOption = streetviewProvider.streetMode;
    final provider = Provider.of<StreetViewProvider>(context, listen: false);
    return BlocListener<MatchUserBloc, MatchUserState>(
      listener: (context, state) {
        if (state is MatchUserLoadedState) {
          setState(() {
            matchedUsers = state.users;
            userIds = matchedUsers
                .where(
                    (user) => user.id != null) // Filter out users with null IDs
                .map((user) => user.id!) // Extract non-null IDs
                .toList();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: Text(
                      'Street View Settings'.tr().toString(),
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  InkResponse(
                    child: selectedOption == 'None'
                        ? Icon(
                            Icons.location_off_outlined,
                            color: primaryColor,
                          )
                        : Icon(
                            Icons.location_on_outlined,
                            color: primaryColor,
                          ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return StatefulBuilder(builder:
                              (BuildContext context, StateSetter setState1) {
                            return AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                title: Text('Who can see my street view'
                                    .tr()
                                    .toString()),
                                content: StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    if (showUserList) {
                                      return matchedUsers.isEmpty
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "You don't have any matches"
                                                      .tr()
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  "Swipe more to find matches!"
                                                      .tr()
                                                      .toString(),
                                                  style: const TextStyle(
                                                      fontSize: 16),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                for (UserModel user
                                                    in matchedUsers)
                                                  CheckboxListTile(
                                                    activeColor: primaryColor,
                                                    title: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 20,
                                                          backgroundImage:
                                                              NetworkImage(user
                                                                  .imageUrl
                                                                  ?.first),
                                                        ),
                                                        const SizedBox(
                                                          width: 5,
                                                        ),
                                                        Text(user.name!),
                                                      ],
                                                    ),
                                                    value: selectedUserIds
                                                        .contains(user.id),
                                                    onChanged:
                                                        (bool? isChecked) {
                                                      setState1(() {
                                                        if (isChecked!) {
                                                          selectedUserIds
                                                              .add(user.id!);
                                                        } else {
                                                          selectedUserIds
                                                              .remove(user.id);
                                                        }
                                                      });
                                                    },
                                                  ),
                                              ],
                                            );
                                    } else {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          RadioListTile<String>(
                                            title: Text(
                                                'Everyone'.tr().toString()),
                                            value: 'Everyone',
                                            activeColor: primaryColor,
                                            groupValue: selectedOption,
                                            onChanged: (String? value) {
                                              setState1(() {
                                                selectedOption = value!;
                                              });

                                              log("theme $value");
                                            },
                                          ),
                                          RadioListTile<String>(
                                            title: Text(
                                                'My Matches'.tr().toString()),
                                            activeColor: primaryColor,
                                            value: 'My Matches',
                                            groupValue: selectedOption,
                                            onChanged: (String? value) {
                                              setState1(() {
                                                selectedOption = value!;
                                                context
                                                    .read<MatchUserBloc>()
                                                    .add(LoadMatchUserEvent(
                                                        currentUser: widget
                                                            .currentUser));
                                              });
                                            },
                                          ),
                                          RadioListTile<String>(
                                            title: Text(
                                                'My Matches including...'
                                                    .tr()
                                                    .toString()),
                                            activeColor: primaryColor,
                                            value: 'Only',
                                            groupValue: selectedOption,
                                            onChanged: (String? value) {
                                              setState1(() {
                                                selectedOption = value!;
                                                showUserList = true;
                                              });
                                            },
                                          ),
                                          RadioListTile<String>(
                                            title:
                                                Text('Nobody'.tr().toString()),
                                            activeColor: primaryColor,
                                            value: 'None',
                                            groupValue: selectedOption,
                                            onChanged: (String? value) {
                                              setState1(() {
                                                selectedOption = value!;
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text(
                                      'Cancel'.tr().toString(),
                                      style: TextStyle(color: secondryColor),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        showUserList = false;
                                        selectedUserIds.clear();
                                      });
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  if (selectedOption != 'Only')
                                    TextButton(
                                      onPressed: () {
                                        switch (selectedOption) {
                                          case 'None':
                                            provider
                                                .toggleView(selectedOption, []);
                                            Navigator.of(dialogContext).pop();
                                            break;
                                          case 'Everyone':
                                            provider
                                                .toggleView(selectedOption, []);
                                            Navigator.of(dialogContext).pop();
                                            break;

                                          case 'My Matches':
                                            provider.toggleView(
                                                selectedOption, userIds);
                                            Navigator.of(dialogContext).pop();
                                            break;
                                        }
                                      },
                                      child: Text(
                                        'Apply'.tr().toString(),
                                        style: TextStyle(color: primaryColor),
                                      ),
                                    )
                                  else if (selectedOption == 'Only' &&
                                      userIds.isNotEmpty &&
                                      selectedUserIds.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        provider.toggleView(
                                            selectedOption, selectedUserIds);
                                        setState(() {
                                          showUserList = false;
                                        });
                                        Navigator.of(dialogContext).pop();
                                      },
                                      child: Text(
                                        'Apply'.tr().toString(),
                                        style: TextStyle(color: primaryColor),
                                      ),
                                    ),
                                ]);
                          });
                        },
                      );
                    },
                  )
                ]),
          ),
        ),
      ),
    );
  }
}
