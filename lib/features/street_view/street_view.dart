// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hookup4u2/common/data/repo/user_messaging_repo.dart';
import 'package:hookup4u2/common/data/repo/user_search_repo.dart';
import 'package:hookup4u2/features/street_view/single_user_html.dart';
import 'package:hookup4u2/features/user/ui/widgets/user_info.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../common/constants/colors.dart';
import '../../common/constants/constants.dart';
import '../../common/providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../explore/bloc/explore_map_bloc.dart';
import 'multi_user_html.dart';

class StreetViewPanoramaInit extends StatefulWidget {
  final List<UserModel> user;
  final UserModel currentUser;
  final bool fromSingleuser;
  final String currentAddressName;
  const StreetViewPanoramaInit({
    super.key,
    required this.user,
    required this.currentUser,
    required this.fromSingleuser,
    required this.currentAddressName,
  });

  @override
  State<StreetViewPanoramaInit> createState() => _StreetViewPanoramaInitState();
}

class _StreetViewPanoramaInitState extends State<StreetViewPanoramaInit> {
  Location location = Location();
  LocationData? _lastLocation;
  SwipableStackController? stackController;
  late final WebViewController controller;
  var loadingPercentage = 0;
  late String data;
  late String htmlContent;

  @override
  void initState() {
    data = widget.user.isEmpty
        ? jsonEncode([
            for (UserModel user in [widget.currentUser])
              [
                {
                  'lat': user.currentCoordinates?['latitude'],
                  'lng': user.currentCoordinates?['longitude'],
                },
                "You",
                "https://i.ibb.co/Yk1t0xv/3603850.png",
                user.id
              ]
          ])
        : jsonEncode([
            for (UserModel user in widget.user)
              [
                {
                  'lat': user.currentCoordinates?['latitude'],
                  'lng': user.currentCoordinates?['longitude'],
                },
                user.name,
                user.imageUrl?.first,
                user.id
              ]
          ]);

    var currentLoc = {
      'lat': widget.currentUser.currentCoordinates?['latitude'],
      'lng': widget.currentUser.currentCoordinates?['longitude']
    };

    _currentLocationUpdate();
// making string of html page to pass in webview
    htmlContent = widget.fromSingleuser
        ? SingleUser.nearBySingleUserPage(
            users: data, currentUserLocation: currentLoc)
        : MultiUser.nearByAllUserPage(
            users: data,
            currentUserLocation: currentLoc,
            currentAddressName: widget.currentAddressName);

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    controller = WebViewController()
      ..addJavaScriptChannel(
        'Hookup4u',
        onMessageReceived: (message) async {
          log("userId is ${message.message}");
          stackController = SwipableStackController();
          final List<UserModel> matches =
              await UserMessagingRepo.getMatches(widget.currentUser);

          bool isMatched = matches.any((user) => user.id == message.message);

          try {
            final user = widget.user.firstWhere(
              (element) => element.id == message.message,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SafeArea(
                  child: Info(
                    user,
                    widget.currentUser,
                    !isMatched,
                    controller: stackController,
                    fromStreetview: true,
                  ),
                ),
              ),
            );
          } catch (e) {
            // Handle the case where no element in widget.user matches the condition
            log("User not found for ID: ${message.message}");
          }
        },
      )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          themeProvider.isDarkMode ? Colors.white : const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) {
            setState(() {
              loadingPercentage = 0;
            });
          }
        },
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              loadingPercentage = progress;
            });
          }
        },
        onPageFinished: (url) {
          if (mounted) {
            setState(() {
              loadingPercentage = 100;
            });
          }
        },
        onWebResourceError: (WebResourceError error) {},
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://www.yt.com/')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(
        Uri.dataFromString(
          htmlContent,
          mimeType: 'text/html',
        ),
      );

    // log("location is ${widget.user.first.currentCoordinates}");
    super.initState();
  }

  void _currentLocationUpdate() async {
    var hasPermission = await location.hasPermission();
    if (hasPermission != PermissionStatus.granted) {
      await location.requestPermission();
    }

    if (hasPermission == PermissionStatus.granted ||
        hasPermission == PermissionStatus.grantedLimited) {
      await location.changeSettings(
        distanceFilter: 100,
        accuracy: LocationAccuracy.high,
      );

      location.onLocationChanged.listen((LocationData newLocation) async {
        if (_lastLocation == null) {
          if (mounted) {
            setState(() {
              _lastLocation = newLocation;
            });
          }

          return;
        }

        var displacement = UserSearchRepo.calculateDistance(
            widget.currentUser.currentCoordinates?['latitude'],
            widget.currentUser.currentCoordinates?['longitude'],
            newLocation.latitude,
            newLocation.longitude);
        log("displacement is $displacement");

        if (displacement >= 0.05) {
          String userId = firebaseAuthInstance.currentUser!.uid;

          // Create a reference to the user's document in Firestore.
          DocumentReference userDocRef =
              firebaseFireStoreInstance.collection('Users').doc(userId);

          // Update the user's current location.
          await userDocRef.update({
            'currentLocation': {
              'latitude': newLocation.latitude,
              'longitude': newLocation.longitude,
              'timestamp':
                  FieldValue.serverTimestamp(), // Optional: Server timestamp.
            },
          });
          if (mounted) {
            setState(() {
              context.read<SearchUserForMapBloc>().add(LoadUserForMapEvent(
                    currentUser: widget.currentUser,
                  ));
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              WebViewWidget(
                controller: controller,
              ),
              if (loadingPercentage < 100)
                LinearProgressIndicator(
                  value: loadingPercentage / 100.0,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
