import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../common/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../payment/ui/products.dart';

class FreeUserMapScreen extends StatelessWidget {
  const FreeUserMapScreen({required this.currentUser, super.key});
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: Stack(
          children: [
            GoogleMapWidget(
              currentUser: currentUser,
            ), // Display the Google Map as the background
            PremiumDialog(
              currentUser: currentUser,
            ), // Display the custom dialog on top
          ],
        ),
      );
}

class GoogleMapWidget extends StatefulWidget {
  const GoogleMapWidget({required this.currentUser, super.key});
  final UserModel currentUser;

  @override
  GoogleMapWidgetState createState() => GoogleMapWidgetState();
}

class GoogleMapWidgetState extends State<GoogleMapWidget> {
  @override
  Widget build(BuildContext context) => GoogleMap(
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        scrollGesturesEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.currentUser.latitude!,
            widget.currentUser.longitude!,
          ), // Replace with your desired map coordinates
          zoom: 15,
        ),
      );
}

class PremiumDialog extends StatelessWidget {
  const PremiumDialog({required this.currentUser, super.key});
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
                      color: AppColors.primaryGreen,
                    ),
                    Text(
                      'This feature requires a subscription. Do you want to subscribe to our plan?'
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryColor,
                        fontSize: 20,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.lock_outline,
                        size: 120,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Products(currentUser, null, const {}),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          AppColors.primaryGreen.withValues(
                              alpha: (0.9 * 255).toDouble()),
                        ),
                      ),
                      child: Text(
                        'Upgrade Now'.tr().toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
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
