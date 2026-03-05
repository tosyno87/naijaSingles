import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../common/constants/app_colors.dart';
import '../../../../../models/user_model.dart';
import 'phone_number.dart';

class UpdateNumber extends StatelessWidget {
  const UpdateNumber(this.currentUser, {super.key});
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          title: Text(
            'Phone number settings'.tr().toString(),
            style: const TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: Theme.of(context).primaryColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Phone number'.tr().toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  onTap: currentUser.phoneNumber!.isNotEmpty
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
                    currentUser.phoneNumber!.isNotEmpty
                        ? '${currentUser.phoneNumber}'
                        : 'Add new Phone number'.tr().toString(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  trailing: Icon(
                    currentUser.phoneNumber!.isNotEmpty
                        ? Icons.done
                        : Icons.add_call,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Text(
                  currentUser.phoneNumber!.isNotEmpty
                      ? 'Verified phone number'.tr().toString()
                      : ' Add Verified phone number'.tr().toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: InkWell(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          currentUser.phoneNumber!.isNotEmpty
                              ? 'Update my phone number'.tr().toString()
                              : 'Add new phone number'.tr().toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhoneNumber(
                          updatePhoneNumber: true,
                        ),
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
