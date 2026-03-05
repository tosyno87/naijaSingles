import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/bloc/theme/theme_bloc.dart';
import '../../../common/constants/app_colors.dart';
import '../../../common/constants/constants.dart';
import '../../../common/utils/custom_toast.dart';
import '../../../common/widgets/hookup_circularbar.dart';
import '../../../common/widgets/image_widget.dart';
import '../../../models/block_user_model.dart';
import '../../../models/user_model.dart';
import '../bloc/bloc_user_list_bloc.dart';

class BlockedUser extends StatefulWidget {
  const BlockedUser({
    required this.currentUser,
    required this.scrollController,
    super.key,
  });
  final UserModel currentUser;
  final ScrollController scrollController;

  @override
  State<BlockedUser> createState() => _BlockedUserState();
}

class _BlockedUserState extends State<BlockedUser> {
  final db = firebaseFireStoreInstance;

  @override
  void initState() {
    context
        .read<BlocUserListBloc>()
        .add(LoadBlockUserEvent(currentUser: widget.currentUser));
    if (mounted) {
      setState(() {});
    }
    widget.scrollController.addListener(_scrollListener);

    super.initState();
  }

  void _scrollListener() {
    if (widget.scrollController.offset >=
            widget.scrollController.position.maxScrollExtent * 0.90 &&
        !widget.scrollController.position.outOfRange) {
      log('load more called');
      // Reached the end of the list, load more items
      context
          .read<BlocUserListBloc>()
          .add(LoadMoreBlockUserEvent(currentUser: widget.currentUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return BlocBuilder<BlocUserListBloc, BlocUserListState>(
      builder: (context, state) {
        if (state is BlockUserLoadingState) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryGreen),
            ),
          );
        }
        if (state is BlockUserFailedState) {
          return Center(
            child: Text(
              'Error to load data.'.tr().toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
                fontStyle: FontStyle.normal,
                letterSpacing: 1,
                fontSize: 18,
              ),
            ),
          );
        }
        if (state is BlockUserLoadedState) {
          return SizedBox(
            child: state.users.isNotEmpty
                ? ListView.builder(
                    controller: widget.scrollController,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(left: 10, top: 15),
                    itemCount: state.users.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == state.users.length) {
                        // Last item in the ListView
                        return const Column(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: Hookup4uBar(),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                          ],
                        );
                      }
                      final BlockUserModel blockUser = state.users[index];
                      return Container(
                        margin: const EdgeInsets.only(
                          top: 5,
                          bottom: 5,
                          right: 20,
                          left: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(90),
                              child: CustomCNImage(
                                imageUrl: blockUser.imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            blockUser.name,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'You blocked this user'.tr().toString(),
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white : Colors.blueGrey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Column(
                            children: [
                              Text(
                                DateFormat('MMM d')
                                    .format(blockUser.blockedTimestamp)
                                    .toString(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext ctx) => ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AlertDialog(
                                  title: Text('Unblock'.tr()),
                                  content: Text(
                                    'Do you want to Unblock'
                                        .tr(args: [blockUser.name]),
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
                                        // Reload the block user list
                                        context.read<BlocUserListBloc>().add(
                                              LoadBlockUserEvent(
                                                currentUser: widget.currentUser,
                                              ),
                                            );
                                        Navigator.pop(ctx);
                                        await db
                                            .collection('chats')
                                            .doc(blockUser.chatID)
                                            .collection('messages')
                                            .doc('blocked')
                                            .set(
                                          {
                                            'isBlocked': false,
                                            'blockedBy': widget.currentUser.id,
                                          },
                                          SetOptions(merge: true),
                                        );
                                        // For deleting from   blocklist
                                        await firebaseFireStoreInstance
                                            .collection('users')
                                            .doc(widget.currentUser.id)
                                            .collection('blockedlist')
                                            .doc(
                                              blockUser.id,
                                            ) // Assuming widget.second.id represents the blocked user's ID
                                            .delete();

                                        CustomToast.showToast(
                                          'User Unblocked Successfully'
                                              .tr()
                                              .toString(),
                                        );
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
                            );
                          },
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No Block user found'.tr().toString(),
                      style: const TextStyle(
                        color: AppColors.secondaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(0),
          child: Center(
            child: Text(
              'No Block user found'.tr().toString(),
              style: const TextStyle(
                color: AppColors.secondaryColor,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
