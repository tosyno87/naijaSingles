// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/data/repo/user_repo.dart';
import '../../../../common/widets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../match/bloc/match_bloc.dart';

class UnMatcheWidget extends StatelessWidget {
  final UserModel currentUser;
  final UserModel user;
  final bool fromChatPage;
  const UnMatcheWidget(
      {super.key,
      required this.currentUser,
      required this.user,
      required this.fromChatPage});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: AlertDialog(
              title: Text(
                'Unmatch'.tr().toString(),
                style: TextStyle(fontSize: 18, color: primaryColor),
              ),
              content: Text(
                  "Do you want to unmatch with"
                      .tr(args: ["${user.name}".toString()]).toString(),
                  style: const TextStyle(fontSize: 16)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No'.tr().toString(),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UserRepo.unmatchUser(currentUser, user.id!);
                    context
                        .read<SearchUserBloc>()
                        .add(LoadUserEvent(currentUser: currentUser));
                    BlocProvider.of<MatchUserBloc>(context)
                        .add(LoadMatchUserEvent(currentUser: currentUser));
                    CustomSnackbar.showSnackBarSimple(
                        "unmatched"
                            .tr(args: ["${user.name}".toString()]).toString(),
                        context);
                    if (fromChatPage) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Yes'.tr().toString(),
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              "UNMATCH WITH"
                  .tr(args: ["${user.name}".toUpperCase()]).toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: secondryColor),
            ),
          )),
    );
  }
}
