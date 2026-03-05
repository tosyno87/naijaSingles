import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/widgets/image_widget.dart';
import '../../../../models/user_model.dart';
import '../../../dating/screens/user_detail_screen.dart';
import '../../../user/ui/widgets/card_level.dart';
import '../../../user/ui/widgets/gender_sign.dart';
import '../../../user/ui/widgets/user_info.dart';
import '../../bloc/searchuser_bloc.dart';

// import 'MatchedAnimation.dart';

class UsersList extends StatefulWidget {
  // NOTE: Do not add profile counters (e.g., "1 of 5 profiles") as they create
  // pressure or anxiety for users

  const UsersList({
    required this.users,
    required this.usersList,
    required this.currentUser,
    required this.stackController,
    required this.onswiped,
    super.key,
  });
  final UserModel currentUser;
  final List<UserModel> users;

  final List<UserModel> usersList;

  final SwipableStackController? stackController;
  final Function(int, SwipeDirection) onswiped;

  @override
  UsersListState createState() => UsersListState();
}

class UsersListState extends State<UsersList> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    widget.stackController?.addListener(() {
      if (widget.usersList.length == widget.stackController?.currentIndex) {
        if (mounted) setState(() {});
        debugPrint('this is the last profile');
      }
    });

    super.initState();
  }

  // Navigate to user profile when card is tapped
  void _navigateToUserProfile(UserModel user) {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetailScreen(user: user),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;
    return widget.usersList.length == widget.stackController?.currentIndex
        ? Align(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    radius: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'asset/images/logo.png',
                        fit: BoxFit.contain,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                Text(
                  "There's no one new around you.".tr().toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: isDarkMode ? Colors.white : Colors.black54,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try expanding your distance or refreshing discovery.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: isDarkMode ? Colors.white70 : Colors.black45,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    context.read<SearchUserBloc>().add(
                          LoadUserEvent(currentUser: widget.currentUser),
                        );
                  },
                  child: const Text('Refresh'),
                ),
              ],
            ),
          )
        : SwipableStack(
            horizontalSwipeThreshold: 0.8,
            verticalSwipeThreshold: 0.8,
            overlayBuilder: (context, properties) {
              final opacity = min(properties.swipeProgress, 1).toDouble();
              if (properties.direction == SwipeDirection.right) {
                return Padding(
                  padding: const EdgeInsets.only(top: 25, left: 25),
                  child: Opacity(opacity: opacity, child: CardLabel.right()),
                );
              } else if (properties.direction == SwipeDirection.left) {
                return Padding(
                  padding: const EdgeInsets.only(top: 25, right: 25),
                  child: Opacity(opacity: opacity, child: CardLabel.left()),
                );
              }
              return Container();
            },
            itemCount: widget.usersList.length,
            onWillMoveNext: (index, direction) {
              final allowedActions = [
                SwipeDirection.right,
                SwipeDirection.left,
              ];
              return allowedActions.contains(direction);
            },
            builder: (context, index) {
              final itemIndex = index.index;

              return Stack(
                children: <Widget>[
                  GestureDetector(
                    onTap: () =>
                        _navigateToUserProfile(widget.users[itemIndex]),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        height: MediaQuery.of(context).size.height * .80,
                        width: MediaQuery.of(context).size.width,
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          child: ColoredBox(
                            color: Colors.white,
                            child: CustomCNImage(
                              imageUrl:
                                  widget.users[itemIndex].imageUrl!.first ?? '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10, left: 15, right: 15),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Stack(
                        children: [
                          DecoratedBox(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black45,
                                  Colors.transparent,
                                ],
                                begin: FractionalOffset(0, 0),
                                end: FractionalOffset(1, 0),
                                stops: [0.0, 1.0],
                              ),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${widget.users[itemIndex].name}, ${widget.users[itemIndex].editInfo!['showMyAge'] != null ? !widget.users[itemIndex].editInfo!['showMyAge'] ? widget.users[itemIndex].age : "" : widget.users[itemIndex].age}",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  if (widget.users[itemIndex]
                                          .editInfo!['showOnProfile'] ??
                                      false)
                                    GenderSign(
                                      gender:
                                          widget.users[itemIndex].userGender!,
                                      iconColor: Colors.white,
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tribe/Nationality
                                    if (widget.users[itemIndex].tribe != null &&
                                        widget
                                            .users[itemIndex].tribe!.isNotEmpty)
                                      Text(
                                        widget.users[itemIndex].tribe!,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    else if (widget
                                                .users[itemIndex].nationality !=
                                            null &&
                                        widget.users[itemIndex].nationality!
                                            .isNotEmpty)
                                      Text(
                                        widget.users[itemIndex].nationality!,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    // Distance
                                    if (widget.users[itemIndex].distanceBW !=
                                        null)
                                      Text(
                                        '${widget.users[itemIndex].distanceBW!.toStringAsFixed(1)} miles away',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      )
                                    else if (widget.users[itemIndex].address !=
                                        null)
                                      Text(
                                        widget.users[itemIndex].address!,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  unawaited(
                                    showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) => Info(
                                        widget.users[itemIndex],
                                        widget.currentUser,
                                        true,
                                        controller: widget.stackController,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.arrow_upward,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ),
                          // Positioned.fill(
                          //   child: Align(
                          //     alignment: Alignment.center,
                          //     child: Container(
                          //       width: 13,
                          //       height: 13,
                          //       decoration: BoxDecoration(
                          //         shape: BoxShape.circle,
                          //         color:
                          //             primaryColor, // Change the color as needed
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            onSwipeCompleted: widget.onswiped,
            controller: widget.stackController,
          );
  }
}
