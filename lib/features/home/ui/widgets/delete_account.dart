import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/text_button.dart';

/// Delete-account entry from settings. Does not perform deletion here:
/// navigates to [AccountDeletionScreen] for a single, consistent delete path
/// (Auth delete + server-side cleanup via Cloud Function).
class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({super.key});

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  @override
  Widget build(BuildContext context) => TextButtonWidget(
        text: 'Delete Account',
        onTap: () async {
          await showDialog<void>(
            context: context,
            builder: (BuildContext context) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surface: Colors.white,
                    ),
                dialogTheme:
                    const DialogThemeData(backgroundColor: Colors.white),
              ),
              child: AlertDialog(
                backgroundColor: Colors.white,
                title: Text('Delete Account'.tr().toString()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Do you want to delete your account?'.tr().toString()),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      "We're sorry to see you go, but we understand your decision. Deleting your account will permanently remove all your personal information and data associated with it."
                          .tr()
                          .toString(),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'No'.tr().toString(),
                      style: const TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _showFinalConfirmationDialog();
                    },
                    child: Text(
                      'Yes'.tr().toString(),
                      style: const TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        icon: Icons.delete_forever_outlined,
      );

  void _showFinalConfirmationDialog() {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: Colors.white,
                ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Final Confirmation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            content: const Text(
              'Are you sure? This cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (!context.mounted) return;
                  unawaited(
                    Navigator.pushNamed(context, RouteName.accountDeletion),
                  );
                },
                child: const Text(
                  'Delete my account',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
