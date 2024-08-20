import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/models/user_model.dart';

import '../../../../common/constants/colors.dart';
import '../../../payment/ui/products.dart';

class PremiumSwipePage extends StatelessWidget {
  final UserModel currentUser;
  const PremiumSwipePage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
          child: Container(
            color: Colors.white.withOpacity(.3),
            child: Dialog(
              insetAnimationCurve: Curves.bounceInOut,
              insetAnimationDuration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 50,
                      color: primaryColor,
                    ),
                    Text(
                      "you have already used the maximum number of free available swipes for 24 hrs."
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.lock_outline,
                        size: 120,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "For swipe more users just subscribe our premium plans."
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          onTap: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Products(currentUser, null, const {})))
              }),
    );
  }
}
