import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../constants/colors.dart';

class BlockByAdmin extends StatefulWidget {
  const BlockByAdmin({super.key});

  @override
  State<BlockByAdmin> createState() => _BlockByAdminState();
}

class _BlockByAdminState extends State<BlockByAdmin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                        height: 50,
                        width: 100,
                        child: Image.asset(
                          "asset/hookup4u-Logo-BP.png",
                          fit: BoxFit.contain,
                        )),
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    Icons.lock_outlined,
                    size: 80,
                    color: primaryColor,
                  ),
                  Text(
                    "Oops".tr().toString(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Sorry, you can't access the application!".tr().toString(),
              style: TextStyle(color: primaryColor, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              "you're blocked by the admin and your profile will also not appear for other users."
                  .tr()
                  .toString(),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "For more info,mail".tr().toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    // Replace this with the appropriate link navigation action
                  },
                  child: const Text(
                    adminMail,
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
