import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../common/constants/colors.dart';
import '../../../../models/user_model.dart';
import '../../../payment/ui/products.dart';

class PremiumSwipePage extends StatelessWidget {
  const PremiumSwipePage({required this.currentUser, super.key});
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) => Align(
        child: InkWell(
          child: ColoredBox(
            color: Colors.white.withValues(alpha: (.3 * 255).toDouble()),
            child: Dialog(
              insetAnimationCurve: Curves.bounceInOut,
              insetAnimationDuration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: primaryColor,
                    ),
                    Text(
                      'you have already used the maximum number of free available swipes for 24 hrs.'
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontSize: 20,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.lock_outline,
                        size: 120,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'For swipe more users just subscribe our premium plans.'
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
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
                builder: (context) => Products(currentUser, null, const {}),
              ),
            ),
          },
        ),
      );
}
