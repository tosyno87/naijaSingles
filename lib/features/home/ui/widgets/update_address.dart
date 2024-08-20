// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/features/home/ui/widgets/subscription_dialog.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:provider/provider.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../bloc/searchuser_bloc.dart';

class UpdateAddressWidget extends StatefulWidget {
  final UserModel currentUser;
  final bool hasSubscription;
  final Map items;
  const UpdateAddressWidget(
      {super.key,
      required this.currentUser,
      required this.hasSubscription,
      required this.items});

  @override
  State<UpdateAddressWidget> createState() => _UpdateAddressWidgetState();
}

class _UpdateAddressWidgetState extends State<UpdateAddressWidget> {
  Map<dynamic, dynamic> selectedLocation = {};

  @override
  void initState() {
    // Assigning values to selectedlocation map
    selectedLocation["address"] = widget.currentUser.address;
    selectedLocation["position"] = {
      "coordinates": [
        widget.currentUser.coordinates!["latitude"],
        widget.currentUser.coordinates!["longitude"],
      ],
    };

    log("selected addresss id $selectedLocation");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        iconColor: primaryColor,
        textColor: primaryColor,
        key: UniqueKey(),
        leading: Text(
          "Current location :".tr().toString(),
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        title: Text(
          widget.currentUser.address ?? "".tr().toString(),
          style: TextStyle(
            color: secondryColor,
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
                Icon(
                  Icons.location_on,
                  color: primaryColor,
                  size: 20,
                ),
                InkWell(
                  child: Text(
                    "Change location".tr().toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    log("hasSubscription $widget.hasSubscription");
                    if (widget.hasSubscription) {
                      var address = await Navigator.pushNamed(
                          context, RouteName.updateLocationScreen,
                          arguments: selectedLocation);
                      log("after pop address is ${address.toString()}");
                      if (address != null) {
                        _updateAddress(address as Map);

                        context.read<SearchUserBloc>().add(
                            LoadUserEvent(currentUser: widget.currentUser));
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
  }

  void _updateAddress(Map<dynamic, dynamic> address) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return Container(
          color: Theme.of(context).primaryColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * .4,
          child: Column(
            children: <Widget>[
              Material(
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black26,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  subtitle: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        address['address'] ?? '',
                        style: TextStyle(
                          color: themeProvider.isDarkMode
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
                  backgroundColor:
                      MaterialStateProperty.all<Color>(primaryColor),
                ),
                child: Text(
                  "Confirm".tr().toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await firebaseFireStoreInstance
                      .collection("Users")
                      .doc('${widget.currentUser.id}')
                      .update({
                        'location': {
                          'latitude': address['position']['coordinates'][1],
                          'longitude': address['position']['coordinates'][0],
                          'address': address['address'],
                        },
                      })
                      .whenComplete(() => showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_) {
                              Future.delayed(const Duration(seconds: 3), () {
                                setState(() {
                                  widget.currentUser.address =
                                      address['address'];
                                });

                                Navigator.pop(context);
                              });
                              return Center(
                                child: Container(
                                  width: 160.0,
                                  height: 120.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.rectangle,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Image.asset(
                                        "asset/auth/verified.jpg",
                                        height: 60,
                                        color: primaryColor,
                                        colorBlendMode: BlendMode.color,
                                      ),
                                      Text(
                                        "location\nchanged".tr().toString(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          decoration: TextDecoration.none,
                                          color: themeProvider.isDarkMode
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
                          ))
                      .catchError((e) {
                        log(e);
                      });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
