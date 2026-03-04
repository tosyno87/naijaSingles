import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../models/user_model.dart';
import '../../bloc/searchuser_bloc.dart';
import 'subscription_dialog.dart';

class UpdateAddressWidget extends StatefulWidget {
  const UpdateAddressWidget({
    required this.currentUser,
    required this.hasSubscription,
    required this.items,
    super.key,
  });
  final UserModel currentUser;
  final bool hasSubscription;
  final Map items;

  @override
  State<UpdateAddressWidget> createState() => _UpdateAddressWidgetState();
}

class _UpdateAddressWidgetState extends State<UpdateAddressWidget> {
  Map<dynamic, dynamic> selectedLocation = {};

  @override
  void initState() {
    // Assigning values to selectedlocation map
    selectedLocation['address'] = widget.currentUser.address;
    selectedLocation['position'] = {
      'coordinates': [
        widget.currentUser.coordinates!['latitude'],
        widget.currentUser.coordinates!['longitude'],
      ],
    };

    log('selected addresss id $selectedLocation');
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          iconColor: AppColors.primaryGreen,
          textColor: AppColors.primaryGreen,
          key: UniqueKey(),
          leading: Text(
            'Current location :'.tr().toString(),
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          title: Text(
            widget.currentUser.address ?? ''.tr().toString(),
            style: const TextStyle(
              color: AppColors.secondaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  InkWell(
                    child: Text(
                      'Change location'.tr().toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      log('hasSubscription $widget.hasSubscription');
                      if (widget.hasSubscription) {
                        final address = await Navigator.pushNamed(
                          context,
                          RouteName.updateLocationScreen,
                          arguments: selectedLocation,
                        );
                        if (!context.mounted) return;
                        log('after pop address is ${address.toString()}');
                        if (address != null) {
                          _updateAddress(address as Map);

                          context.read<SearchUserBloc>().add(
                                LoadUserEvent(currentUser: widget.currentUser),
                              );
                        }
                      } else {
                        showSubscriptionDialog(
                          context: context,
                          currentUser: widget.currentUser,
                          items: widget.items,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      );

  void _updateAddress(Map<dynamic, dynamic> address) {
    unawaited(showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final themeBloc = context.read<ThemeBloc>();
        final isDarkMode = themeBloc.isDarkMode;
        return Container(
          color: Theme.of(context).primaryColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * .4,
          child: Column(
            children: <Widget>[
              Material(
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'New address:'.tr().toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black26,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  subtitle: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        address['address'] ?? '',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(AppColors.primaryGreen),
                ),
                child: Text(
                  'Confirm'.tr().toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await firebaseFireStoreInstance
                      .collection('users')
                      .doc('${widget.currentUser.id}')
                      .update({
                        'location': {
                          'latitude': address['position']['coordinates'][1],
                          'longitude': address['position']['coordinates'][0],
                          'address': address['address'],
                        },
                      })
                      .whenComplete(
                        () {
                          if (!mounted) return;
                          unawaited(showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (_) {
                            unawaited(Future.delayed(const Duration(seconds: 3), () {
                              if (!mounted) return;
                              setState(() {
                                widget.currentUser.address = address['address'];
                              });

                              Navigator.pop(context);
                            }));
                            return Center(
                              child: Container(
                                width: 160,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      'asset/auth/verified.jpg',
                                      height: 60,
color: AppColors.primaryGreen,
                                    colorBlendMode: BlendMode.color,
                                    ),
                                    Text(
                                      'location\nchanged'.tr().toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        decoration: TextDecoration.none,
                                        color: isDarkMode
                                            ? Colors.black
                                            : Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ));
                      })
                      .catchError((Object error, StackTrace stackTrace) {
                        log(
                          'Failed to update user location',
                          error: error,
                          stackTrace: stackTrace,
                        );
                      });
                },
              ),
            ],
          ),
        );
      },
    ));
  }
}
