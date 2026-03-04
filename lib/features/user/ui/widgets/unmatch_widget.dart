import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/data/repo/user_repo.dart';
import '../../../../common/widgets/custom_snackbar.dart';
import '../../../../models/user_model.dart';
import '../../../home/bloc/searchuser_bloc.dart';
import '../../../match/bloc/match_user_bloc.dart';

class UnMatcheWidget extends StatelessWidget {
  const UnMatcheWidget({
    required this.currentUser,
    required this.user,
    required this.fromChatPage,
    super.key,
  });
  final UserModel currentUser;
  final UserModel user;
  final bool fromChatPage;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (BuildContext ctx) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AlertDialog(
              title: Text(
                'Unmatch'.tr().toString(),
                style: const TextStyle(fontSize: 18, color: AppColors.primaryGreen),
              ),
              content: Text(
                'Do you want to unmatch with'
                    .tr(args: ['${user.name}'.toString()]).toString(),
                style: const TextStyle(fontSize: 16),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UserRepo.unmatchUser(currentUser, user.id!);
                    if (!context.mounted) return;
                    context
                        .read<SearchUserBloc>()
                        .add(LoadUserEvent(currentUser: currentUser));
                    BlocProvider.of<MatchUserBloc>(context)
                        .add(LoadMatchUserEvent(currentUser: currentUser));
                    CustomSnackbar.showSnackBarSimple(
                      'unmatched'
                          .tr(args: ['${user.name}'.toString()]).toString(),
                      context,
                    );
                    if (fromChatPage) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Yes'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              'UNMATCH WITH'
                  .tr(args: ['${user.name}'.toUpperCase()]).toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryColor,
              ),
            ),
          ),
        ),
      );
}
