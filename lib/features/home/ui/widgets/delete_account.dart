import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/widgets/delete_account_themed_dialog.dart';
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
          await showAccountDeletionThemedDialog<void>(
            context,
            (dialogCtx) => AlertDialog(
              backgroundColor: deleteAccountDialogBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: Text('Delete Account'.tr().toString()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Delete your account permanently?'.tr().toString()),
                  const SizedBox(height: 8),
                  Text(
                    'This removes your profile, matches, and messages. This cannot be undone.'
                        .tr()
                        .toString(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'No'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _showFinalConfirmationDialog();
                  },
                  child: Text(
                    'Yes'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          );
        },
        icon: Icons.delete_forever_outlined,
      );

  void _showFinalConfirmationDialog() {
    unawaited(
      showAccountDeletionThemedDialog<void>(
        context,
        (dialogCtx) => AlertDialog(
          backgroundColor: deleteAccountDialogBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Final Confirmation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: const Text(
            'Final check: this permanently deletes your account and data.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                if (!mounted) return;
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
    );
  }
}
