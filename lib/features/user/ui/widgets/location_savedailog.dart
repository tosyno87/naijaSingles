import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/widgets/hookup_circularbar.dart';

Future<Map<String, dynamic>?> showLocationDialog(
  BuildContext context,
  double? latitude,
  double? longitude,
) {
  final Map<String, dynamic> updatedLocation = {};
  final isDarkMode = context.read<ThemeBloc>().isDarkMode;
  return showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (BuildContext context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save changes!'.tr().toString(),
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to continue with this location?'.tr().toString(),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            FutureBuilder(
              future: getAddress(latitude, longitude),
              builder: (BuildContext ctx, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Hookup4uBar());
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${snapshot.data ?? 'loading...'.tr().toString()}',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'No'.tr().toString(),
                            style: const TextStyle(color: primaryColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            updatedLocation.addAll({
                              'position': {
                                'coordinates': <double>[
                                  longitude ?? 0.0,
                                  latitude ?? 0.0,
                                ],
                              },
                              'address': snapshot.data?.toString() ?? '',
                            });
                            log('new address is $updatedLocation');
                            Navigator.pop(context, updatedLocation);
                          },
                          child: Text(
                            'Yes'.tr().toString(),
                            style: const TextStyle(color: primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showAddressDialog(
  BuildContext context,
  double latitude,
  double longitude,
) =>
    showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) => FutureBuilder(
        future: getAddress(latitude, longitude),
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: const Center(child: Hookup4uBar()),
              content: Text(
                'loading...'.tr().toString(),
                textAlign: TextAlign.center,
              ),
            );
          } else if (snapshot.hasError) {
            return AlertDialog(
              title: Text('${snapshot.error}'),
            );
          } else if (snapshot.hasData) {
            return AlertDialog(
              title: Text('${snapshot.data}'),
            );
          }
          return Container();
        },
      ),
    );

Future getAddress(lat, lng) async {
  try {
    final reverseGeocode = await UserLocationReporistoryImpl()
        .getReverseGeoding(lat: lat, lng: lng);
    return reverseGeocode.formattedAddress;
  } on SocketException {
    throw 'No internet connection'.tr().toString();
  } catch (e) {
    rethrow;
  }
}
