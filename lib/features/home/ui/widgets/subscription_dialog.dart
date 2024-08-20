import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/constants/colors.dart';

import '../../../../models/user_model.dart';
import '../../../payment/ui/products.dart';

void showSubscriptionDialog({
  required BuildContext context,
  required UserModel currentUser,
  required Map items,
}) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Subscription Required'.tr().toString(),
                style: TextStyle(fontSize: 18, color: primaryColor),
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
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to the subscription page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Products(currentUser, null, items),
                        ),
                      );
                    },
                    child: Text(
                      'Yes'.tr().toString(),
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
