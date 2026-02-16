// ignore_for_file: unnecessary_string_interpolations, use_build_context_synchronously, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utils/app_exit.dart';
import '../../../../models/user_model.dart';
import '../../../explore/explore_screen.dart';
import '../../../messages/messages_screen.dart';
import '../../../profile/profile_screen.dart';
import '../screens/home_page.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Handle non-call notifications in background
  if (message.data['type'] != 'Call') {
    // Handle other notification types
    debugPrint('Background message: ${message.data}');
  }
}

class Tabbar extends StatefulWidget {
  const Tabbar({super.key, this.isPaymentSuccess, this.currentUserId});
  final bool? isPaymentSuccess;
  final String? currentUserId;

  @override
  TabbarState createState() => TabbarState();
}

class TabbarState extends State<Tabbar> with WidgetsBindingObserver {
  List<UserModel> users = [];
  int swipedcount = 0;
  int currentIndex = 0;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase iap = InAppPurchase.instance;
  Set<String> shownNotificationForegroundIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initFirebase(context);

    final Stream<List<PurchaseDetails>> purchaseUpdated = iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) async {
      for (var purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.status == PurchaseStatus.purchased) {
          debugPrint('Purchase successful: ${purchaseDetails.productID}');
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        }
      }
    });

    if (widget.isPaymentSuccess != null && widget.isPaymentSuccess!) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final isDarkMode = context.read<ThemeBloc>().isDarkMode;
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: isDarkMode
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: Text(
              'Payment Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  void initFirebase(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final String notificationId = message.data['notificationId'] ?? '';

      if (shownNotificationForegroundIds.contains(notificationId)) {
        return;
      }

      shownNotificationForegroundIds.add(notificationId);
      // Handle non-call notifications only
      if (message.data['type'] != 'Call') {
        // Handle other notification types (messages, matches, etc.)
        debugPrint('Received notification: ${message.data}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      final String notificationId = message.data['notificationId'] ?? '';

      if (shownNotificationForegroundIds.contains(notificationId)) {
        return;
      }

      shownNotificationForegroundIds.add(notificationId);
      // Handle non-call notifications only
      if (message.data['type'] != 'Call') {
        // Navigate to appropriate screen based on notification type
        if (message.data['type'] == 'message') {
          Navigator.pushNamed(
            context,
            RouteName.tabScreen,
            arguments: 'messages',
          );
        } else {
          Navigator.pushNamed(
            context,
            RouteName.tabScreen,
            arguments: 'notification',
          );
        }
      }
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) async {
      if (message != null) {
        final String notificationId = message.data['notificationId'] ?? '';

        if (shownNotificationForegroundIds.contains(notificationId)) {
          return;
        }

        shownNotificationForegroundIds.add(notificationId);
        // Handle non-call notifications only
        if (message.data['type'] != 'Call') {
          // Handle app launch from notification
          debugPrint('App launched from notification: ${message.data}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldExit = await onWillPop(context);
        if (shouldExit && context.mounted) {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          } else if (Platform.isIOS) {
            exit(0);
          }
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              title: TabBar(
                labelColor:
                    isDarkMode ? Colors.white : AppColors.primaryGreen,
                unselectedLabelColor: isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
                indicatorColor: AppColors.primaryGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.home_outlined, size: 24),
                    text: 'Home',
                  ),
                  Tab(
                    icon: Icon(Icons.explore_outlined, size: 24),
                    text: 'Explore',
                  ),
                  Tab(
                    icon: Icon(Icons.message_outlined, size: 24),
                    text: 'Messages',
                  ),
                  Tab(
                    icon: Icon(Icons.person_outline, size: 24),
                    text: 'Profile',
                  ),
                ],
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
              ),
            ),
          ),
          body: const TabBarView(
            children: [
              Homepage(
                items: {},
                isPurchased: false,
              ), // Use existing Homepage
              ExploreScreen(),
              MessagesScreen(),
              ProfileScreen(),
            ],
          ),
        ),
      ),
    );
  }
}
