import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:naijasingles/config/app_config.dart';
import '../../../../../common/utils/privacy_page.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          child: Text(
            "Privacy Policy".tr().toString(),
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyPage(
                url: privacyUrl,
                tittle: "Privacy Policy",
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 10, right: 10),
          height: 4,
          width: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.green[700],
          ),
        ),
        GestureDetector(
          child: Text(
            "Terms & Conditions".tr().toString(),
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyPage(
                url: termConditionUrl,
                tittle: "Terms & Conditions",
              ),
            ),
          ),
        ),
      ],
    );
  }
}
