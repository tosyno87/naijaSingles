import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../common/constants/app_colors.dart';

import '../../../../models/user_model.dart';
import '../../../payment/ui/products.dart';

Future<void> showSubscriptionDialog({
  required BuildContext context,
  required UserModel currentUser,
  required Map items,
}) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Subscription Required'.tr().toString(),
              style:
                  const TextStyle(fontSize: 18, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 10),
            Text(
              'This feature requires a subscription. Do you want to subscribe to our plan?'
                  .tr()
                  .toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Products(currentUser, null, items),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Yes'.tr().toString(),
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
