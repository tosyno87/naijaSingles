import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/streetview/streetview_bloc.dart';
import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../match/bloc/match_user_bloc.dart';

class StreetViewButtonWigdet extends StatefulWidget {
  const StreetViewButtonWigdet({required this.currentUser, super.key});
  final UserModel currentUser;

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
    final themeBloc = context.watch<ThemeBloc>();
    final isDarkMode = themeBloc.isDarkMode;
    final streetViewBloc = context.watch<StreetViewBloc>();
    String selectedOption = streetViewBloc.currentStreetMode ?? 'None';
    return BlocListener<MatchUserBloc, MatchUserState>(
      listener: (context, state) {
        if (state is MatchUserLoadedState) {
          setState(() {
            matchedUsers = state.users;
            userIds = matchedUsers
                .where(
                  (user) => user.id != null,
                ) // Filter out users with null IDs
                .map((user) => user.id!) // Extract non-null IDs
                .toList();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Text(
                    'Street View Settings'.tr().toString(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : AppColors.primaryGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkResponse(
                  child: selectedOption == 'None'
                      ? const Icon(
                          Icons.location_off_outlined,
                          color: AppColors.primaryGreen,
                        )
                      : const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryGreen,
                        ),
                  onTap: () {
                    final streetViewBloc = context.read<StreetViewBloc>();
                    unawaited(
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) =>
                            StatefulBuilder(
                          builder:
                              (BuildContext context, StateSetter setState1) =>
                                  AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            title: Text(
                              'Who can see my street view'.tr().toString(),
                            ),
                            content: StatefulBuilder(
                              builder: (
                                BuildContext context,
                                StateSetter setState,
                              ) {
                                if (showUserList) {
                                  return matchedUsers.isEmpty
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "You don't have any matches"
                                                  .tr()
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Swipe more to find matches!'
                                                  .tr()
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            for (UserModel user in matchedUsers)
                                              CheckboxListTile(
                                                activeColor:
                                                    AppColors.primaryGreen,
                                                title: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundImage:
                                                          NetworkImage(
                                                        user.imageUrl?.first,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(user.name!),
                                                  ],
                                                ),
                                                value: selectedUserIds
                                                    .contains(user.id),
                                                onChanged: (bool? isChecked) {
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
                                          'Everyone'.tr().toString(),
                                        ),
                                        value: 'Everyone',
                                        activeColor: AppColors.primaryGreen,
                                        // ignore: deprecated_member_use
                                        groupValue: selectedOption,
                                        // ignore: deprecated_member_use
                                        onChanged: (String? value) {
                                          setState1(() {
                                            selectedOption = value!;
                                          });

                                          log('theme $value');
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text(
                                          'My Matches'.tr().toString(),
                                        ),
                                        activeColor: AppColors.primaryGreen,
                                        value: 'My Matches',
                                        // ignore: deprecated_member_use
                                        groupValue: selectedOption,
                                        // ignore: deprecated_member_use
                                        onChanged: (String? value) {
                                          setState1(() {
                                            selectedOption = value!;
                                            context.read<MatchUserBloc>().add(
                                                  LoadMatchUserEvent(
                                                    currentUser:
                                                        widget.currentUser,
                                                  ),
                                                );
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text(
                                          'My Matches including...'
                                              .tr()
                                              .toString(),
                                        ),
                                        activeColor: AppColors.primaryGreen,
                                        value: 'Only',
                                        // ignore: deprecated_member_use
                                        groupValue: selectedOption,
                                        // ignore: deprecated_member_use
                                        onChanged: (String? value) {
                                          setState1(() {
                                            selectedOption = value!;
                                            showUserList = true;
                                          });
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: Text('Nobody'.tr().toString()),
                                        activeColor: AppColors.primaryGreen,
                                        value: 'None',
                                        // ignore: deprecated_member_use
                                        groupValue: selectedOption,
                                        // ignore: deprecated_member_use
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
                                  style: const TextStyle(
                                    color: AppColors.secondaryColor,
                                  ),
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
                                        streetViewBloc.add(
                                          StreetViewModeChanged(
                                            selectedOption,
                                            const [],
                                          ),
                                        );
                                        Navigator.of(dialogContext).pop();
                                        break;
                                      case 'Everyone':
                                        streetViewBloc.add(
                                          StreetViewModeChanged(
                                            selectedOption,
                                            const [],
                                          ),
                                        );
                                        Navigator.of(dialogContext).pop();
                                        break;

                                      case 'My Matches':
                                        streetViewBloc.add(
                                          StreetViewModeChanged(
                                            selectedOption,
                                            userIds,
                                          ),
                                        );
                                        Navigator.of(dialogContext).pop();
                                        break;
                                    }
                                  },
                                  child: Text(
                                    'Apply'.tr().toString(),
                                    style: const TextStyle(
                                        color: AppColors.primaryGreen),
                                  ),
                                )
                              else if (selectedOption == 'Only' &&
                                  userIds.isNotEmpty &&
                                  selectedUserIds.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    streetViewBloc.add(
                                      StreetViewModeChanged(
                                        selectedOption,
                                        selectedUserIds,
                                      ),
                                    );
                                    setState(() {
                                      showUserList = false;
                                    });
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text(
                                    'Apply'.tr().toString(),
                                    style: const TextStyle(
                                        color: AppColors.primaryGreen),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
