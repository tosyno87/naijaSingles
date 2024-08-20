import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';

class NotificatioWidget extends StatelessWidget {
  const NotificatioWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        "App settings".tr().toString(),
        style: TextStyle(
            color: primaryColor, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      subtitle: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Notifications".tr().toString(),
                      style: TextStyle(
                          fontSize: 18,
                          color: primaryColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Push notifications".tr().toString()),
                  ),
                ],
              ),
              Icon(
                Icons.edit_notifications_outlined,
                size: 20,
                color: primaryColor,
              )
            ],
          ),
        ),
      ),
    );
  }
}
