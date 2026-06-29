import 'dart:async';

import 'package:dlibphonenumber/dlibphonenumber.dart' hide PhoneNumber;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../../../common/widgets/afropeep_app_bar.dart';
import '../../../../../models/user_model.dart';
import 'phone_number.dart';

String _formatDisplayPhone(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  try {
    final phoneUtil = PhoneNumberUtil.instance;
    if (trimmed.startsWith('+')) {
      final parsed = phoneUtil.parse(trimmed, null);
      return phoneUtil.format(parsed, PhoneNumberFormat.international);
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('1')) {
      final parsed = phoneUtil.parse('+$digits', null);
      return phoneUtil.format(parsed, PhoneNumberFormat.international);
    }

    final parsed = phoneUtil.parse(digits, 'US');
    return phoneUtil.format(parsed, PhoneNumberFormat.international);
  } on Object {
    return trimmed;
  }
}

class UpdateNumber extends StatelessWidget {
  const UpdateNumber(this.currentUser, {super.key});
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    final bool hasPhone = currentUser.phoneNumber!.isNotEmpty;
    final String displayPhone =
        hasPhone ? _formatDisplayPhone(currentUser.phoneNumber!) : '';

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AfropeepAppBar(
        title: 'Phone number'.tr().toString(),
        titleColor: AppColors.textOnPrimary,
        backButtonColor: AppColors.textOnPrimary,
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                onTap: hasPhone
                    ? null
                    : () {
                        unawaited(
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhoneNumber(
                                updatePhoneNumber: true,
                              ),
                            ),
                          ),
                        );
                      },
                title: Text(
                  hasPhone
                      ? displayPhone
                      : 'Add new Phone number'.tr().toString(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Icon(
                  hasPhone ? Icons.done : Icons.add_call,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasPhone
                  ? 'Verified phone number'.tr().toString()
                  : ' Add Verified phone number'.tr().toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textOnPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhoneNumber(
                      updatePhoneNumber: true,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    hasPhone
                        ? 'Update my phone number'.tr().toString()
                        : 'Add new phone number'.tr().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
