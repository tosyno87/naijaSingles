// ignore_for_file: unnecessary_string_interpolations, use_build_context_synchronously, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:hookup4u2/common/utlis/app_exit.dart';
import 'package:hookup4u2/features/calling/ui/screens/call.dart';
import 'package:hookup4u2/features/explore/explore_map.dart';
import 'package:hookup4u2/features/match/ui/screen/match_page.dart';
import 'package:hookup4u2/models/user_model.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:uuid/uuid.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/providers/user_provider.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utlis/blockedby_admin.dart';
import '../../../../services/notificatiion.dart';
import '../../../chat/ui/screens/chat_page.dart';
import '../../../notifications/notifications.dart';
import '../../../user/ui/screens/user_profile.dart';
import '../screens/home_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");

  await Firebase.initializeApp();

  if (message.data['type'] == 'Call') {
    NotificationData.showCallkitIncoming(
        channelId: message.data['channel_id'],
        name: message.data['senderName'],
        avatar: message.data['senderPicture'],
        callTime: message.data['time'],
        uuid: const Uuid().v4(),
        callType: message.notification?.body);
  }
}

class Tabbar extends StatefulWidget {
  final bool? isPaymentSuccess;
  final String? plan;
  const Tabbar(this.plan, this.isPaymentSuccess, {super.key});
  @override
  TabbarState createState() => TabbarState();
}

//_
class TabbarState extends State<Tabbar> with WidgetsBindingObserver {
  CollectionReference callRef = firebaseFireStoreInstance.collection("calls");
  List<UserModel> users = [];
  int swipedcount = 0;
  late final Uuid _uuid;
  String? currentUuid;
  String textEvents = "";
  List<PurchaseDetails> purchases = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final InAppPurchase iap = InAppPurchase.instance;
  bool isPuchased = false;

  // Set to store notification IDs that have been displayed
  Set<String?> shownNotificationForegroundIds = {};

  @override
  void initState() {
    _uuid = const Uuid();
    currentUuid = "";
    WidgetsBinding.instance.addObserver(this);
    initFirebase(context);
    listenerEvent(onEvent);
    checkAndNavigationCallingPageFromTerminated();
    final Stream<List<PurchaseDetails>> purchaseUpdated = iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) async {
      setState(() {
        purchases.addAll(purchaseDetailsList);
        listenToPurchaseUpdated(purchaseDetailsList);
      });
    }, onDone: () {
      _subscription!.cancel();
    }, onError: (error) {
      _subscription!.cancel();
    });

    super.initState();

// when any background message recieve

    _getAccessItems();
    _getpastPurchases();

    if (widget.isPaymentSuccess != null && widget.isPaymentSuccess!) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        await Alert(
          context: context,
          style: AlertStyle(
              backgroundColor: Theme.of(context).primaryColor,
              titleStyle: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
              descStyle: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black)),
          type: AlertType.success,
          title: "Confirmation".tr().toString(),
          desc: "You have successfully subscribed to our"
              .tr(args: ["${widget.plan}"]),
          buttons: [
            DialogButton(
              onPressed: () => Navigator.pop(context),
              width: 120,
              color: primaryColor,
              child: Text(
                "Ok".tr().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            )
          ],
        ).show();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription!.cancel();
    super.dispose();
  }

  initFirebase(BuildContext context) async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
    currentUuid = _uuid.v4();
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // debugPrint('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // debugPrint('User granted provisional permission');
    } else {
      // debugPrint('User declined or has not accepted permission');
    }

    // when user tap on msg fron terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      debugPrint("RemoteMessage  ${message?.data}");
      // Generate a unique notification ID
      String? notificationId = message?.messageId;
      // Check if the notification ID has already been shown
      if (shownNotificationForegroundIds.contains(notificationId)) {
        // If the ID has already been shown, do not process the notification
        return;
      }
      // Add the notification ID to the set of shown notification IDs
      shownNotificationForegroundIds.add(notificationId);
      if (message != null) {
        bool iscallling =
            await NotificationData.checkcallState(message.data['channel_id']);
        if (message.data['type'] == 'Call' && iscallling) {
          NotificationData.showCallkitIncoming(
              channelId: message.data['channel_id'],
              name: message.data['senderName'],
              avatar: message.data['senderPicture'],
              callTime: message.data['time'],
              uuid: currentUuid!,
              callType: message.notification?.body);
        } else if (message.data['type'] == 'Call' && !iscallling) {
          Navigator.pushReplacementNamed(context, RouteName.tabScreen,
              arguments: "notification");
        } else {
          UserModel sender =
              UserModel.convertStringToUserModel(message.data['sender']);
          UserModel second =
              UserModel.convertStringToUserModel(message.data['second']);

          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatPage(
                      sender: sender,
                      second: second,
                      chatId: message.data['channel_id'])));
        }
      } else {}
    });

    // when user tap on notification in background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('onMessageOpenedApp data: ${message.data}');
      debugPrint('onMessageOpenedApp type: ${message.data['type']}');
      // Generate a unique notification ID
      String? notificationId = message.messageId;
      // Check if the notification ID has already been shown
      if (shownNotificationForegroundIds.contains(notificationId)) {
        // If the ID has already been shown, do not process the notification
        return;
      }
      // Add the notification ID to the set of shown notification IDs
      shownNotificationForegroundIds.add(notificationId);
      bool iscallling =
          await NotificationData.checkcallState(message.data['channel_id']);
      if (message.data['type'] == 'Call' && iscallling) {
        NotificationData.showCallkitIncoming(
            channelId: message.data['channel_id'],
            name: message.data['senderName'],
            avatar: message.data['senderPicture'],
            callTime: message.data['time'],
            uuid: currentUuid!,
            callType: message.notification?.body);
        // Handle the call based on the call type
      } else if (message.data['type'] == 'Call' && !iscallling) {
        Navigator.pushReplacementNamed(context, RouteName.tabScreen,
            arguments: "notification");
      } else {
        UserModel sender =
            UserModel.convertStringToUserModel(message.data['sender']);
        UserModel second =
            UserModel.convertStringToUserModel(message.data['second']);
        debugPrint("sender is ${message.data['sender']}");
        debugPrint("second  is $sender");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                    sender: sender,
                    second: second,
                    chatId: message.data['channel_id'])));
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
          'Message title: ${message.notification?.title}, body: ${message.notification?.body}, data: ${message.data}');
      // Generate a unique notification ID
      String? notificationId = message.messageId;
      // Check if the notification ID has already been shown
      if (shownNotificationForegroundIds.contains(notificationId)) {
        // If the ID has already been shown, do not process the notification
        return;
      }
      // Add the notification ID to the set of shown notification IDs
      shownNotificationForegroundIds.add(notificationId);
      if (message.data['type'] == 'Call') {
        NotificationData.showCallkitIncoming(
            uuid: currentUuid!,
            channelId: message.data['channel_id'],
            name: message.data['senderName'],
            avatar: message.data['senderPicture'],
            callType: message.notification?.body,
            callTime: message.data['time']);
      } else {}
    });
  }

  Map items = {};
  _getAccessItems() async {
    firebaseFireStoreInstance
        .collection("Item_access")
        .snapshots()
        .listen((doc) {
      if (doc.docs.isNotEmpty) {
        items = doc.docs[0].data();
        debugPrint(doc.docs[0].data().toString());
      }
    });
  }

  void listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          //  _showPendingUI();
          debugPrint('===pending...  ${purchaseDetails.productID}');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyPuchase(purchaseDetails.productID);

          break;
        case PurchaseStatus.error:
          debugPrint(purchaseDetails.error!.toString());

          break;
        default:
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await iap.completePurchase(purchaseDetails);
      }
    });
  }

  Future<void> _getpastPurchases() async {
    debugPrint('===past purchses----');
    bool isAvailable = await iap.isAvailable();
    if (isAvailable) {
      await iap.restorePurchases();
    }
  }

  /// check if user has pruchased
  PurchaseDetails _hasPurchased(String productId) {
    debugPrint('======**************');
    return purchases.firstWhere(
      (purchase) => purchase.productID == productId,
      // orElse: () => null
    );
  }

  ///verifying pourchase of user
  Future<void> _verifyPuchase(String id) async {
    PurchaseDetails purchase = _hasPurchased(id);
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      debugPrint(purchase.productID);
      if (Platform.isIOS) {
        await iap.completePurchase(purchase);

        isPuchased = true;
      }
      isPuchased = true;
    } else {
      isPuchased = false;
    }
  }

  // For checking user has granted notification permission or not
  Future<bool> checkNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return true;
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      return true;
    } else {
      return false;
    }
  }

  // When user pick the call from terminated state

  checkAndNavigationCallingPageFromTerminated() async {
    var currentCall = await getCurrentCall();
    bool isPermissionallowed = await checkNotificationPermission();

    if (currentCall != null && isPermissionallowed) {
      int givenTimestamp =
          int.parse(currentCall['extra']['callTime']); // Example timestamp

// Get the current timestamp in milliseconds
      int currentTimestamp = DateTime.now().millisecondsSinceEpoch;

// Calculate the difference in milliseconds
      int differenceInMilliseconds = currentTimestamp - givenTimestamp;

// Convert difference from milliseconds to seconds
      int differenceInSeconds = (differenceInMilliseconds / 1000).round();
      debugPrint("diffrence is $differenceInSeconds");

      if (differenceInSeconds <= 40) {
        debugPrint("current call is after terminating $currentCall");
        await callRef
            .doc(currentCall['extra']['channelId'])
            .update({'response': "Pickup"});
        debugPrint('call not  expired');
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CallPage(
                      callType: currentCall['extra']['callType'],
                      channelName: currentCall['extra']['channelId'],
                      role: ClientRoleType.clientRoleBroadcaster,
                    )));
      } else {
        debugPrint('call expired');
        await FlutterCallkitIncoming.endCall(currentCall['id']);
      }
    } else {
      debugPrint('call null');
    }
  }

  getCurrentCall() async {
    //check current call from pushkit if possible
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List) {
      if (calls.isNotEmpty) {
        debugPrint('DATA: $calls');
        currentUuid = calls[0]['id'];
        return calls[0];
      } else {
        currentUuid = "";
        return null;
      }
    }
  }

  Future<void> listenerEvent(Function? callback) async {
    try {
      FlutterCallkitIncoming.onEvent.listen((event) async {
        if (kDebugMode) {
          print('HOME: $event');
        }
        switch (event!.event) {
          case Event.actionCallIncoming:
            break;
          case Event.actionCallStart:
            break;
          case Event.actionCallAccept:
            await checkAndNavigationCallingPage(
                channelId: event.body['extra']['channelId'],
                callType: event.body['extra']['callType'] ?? '');
            FlutterCallkitIncoming.setCallConnected(event.body['id']);
            break;
          case Event.actionCallDecline:
            await callRef
                .doc(event.body['extra']['channelId'])
                .update({'response': 'Decline'});
            await FlutterCallkitIncoming.endAllCalls();

            debugPrint(
                'decilne incoming dart------------------------------------');

            break;
          case Event.actionCallEnded:
            debugPrint(
                "call id from call ended state is ${event.body['extra']['channelId']}");
            try {
              await callRef
                  .doc(event.body['extra']['channelId'])
                  .update({'response': 'Decline'});
              debugPrint('completed call------------------------------------');
            } catch (e) {
              await FlutterCallkitIncoming.endAllCalls();
              rethrow;
            }

            await FlutterCallkitIncoming.endCall(event.body['id']);

            break;
          case Event.actionCallTimeout:
            await callRef
                .doc(event.body['extra']['channelId'])
                .update({'response': 'Not-answer'});
            await FlutterCallkitIncoming.endCall(event.body['id']);
            await FlutterCallkitIncoming.endAllCalls();

            debugPrint(
                'decilne incoming dart------------------------------------');
            break;
          case Event.actionCallCallback:
            break;
          case Event.actionCallToggleHold:
            break;
          case Event.actionCallToggleMute:
            break;
          case Event.actionCallToggleDmtf:
            break;
          case Event.actionCallToggleGroup:
            break;
          case Event.actionCallToggleAudioSession:
            break;
          case Event.actionDidUpdateDevicePushTokenVoip:
            break;
          case Event.actionCallCustom:
            break;
        }
        if (callback != null) {
          callback(event.toString());
        }
      });
    } on Exception {
      rethrow;
    }
  }

  // when user pick the call from opened app or background to navigate on call screen

  Future<void> checkAndNavigationCallingPage({
    required String channelId,
    required String callType,
  }) async {
    var currentCall = await getCurrentCall();
    if (currentCall != null) {
      int givenTimestamp =
          int.parse(currentCall['extra']['callTime']); // Example timestamp

// Get the current timestamp in seconds
      int currentTimestampInSeconds =
          DateTime.now().millisecondsSinceEpoch ~/ 1000;

// Calculate the difference in seconds
      int differenceDuration = currentTimestampInSeconds - givenTimestamp;
      debugPrint("diffrence is $differenceDuration");

      if (differenceDuration <= 30) {
        debugPrint('call not expired');
        await callRef
            .doc(currentCall['extra']['channelId'])
            .update({'response': "Pickup"});
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CallPage(
                      callType: callType,
                      channelName: channelId,
                      role: ClientRoleType.clientRoleBroadcaster,
                    )));
      } else {
        debugPrint('call expired');
        await callRef
            .doc(currentCall['extra']['channelId'])
            .update({'response': 'Not-answer'});
        await FlutterCallkitIncoming.endCall(currentCall['id']);
      }
    } else {
      debugPrint('call null');
    }
  }

  onEvent(event) {
    if (!mounted) return;
    setState(() {
      textEvents += "${event.toString()}\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatdata = ModalRoute.of(context)!.settings.arguments.toString();
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    // debugPrint("user print ${userProvider.currentUser.toString()}");
    FirebaseMessaging.instance.getToken().then((token) async {
      debugPrint('Device Token FCM: $token');
      await firebaseFireStoreInstance
          .collection('Users')
          .doc(userProvider.currentUser!.id)
          .update({'pushToken': token});
      if (!isPuchased) {
        await firebaseFireStoreInstance
            .collection('Users')
            .doc(userProvider.currentUser!.id)
            .update({'isPremium': false});
      }
    });
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await onWillPop(context);
        if (shouldPop) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        body: userProvider.currentUser!.isBlocked!
            ? const BlockByAdmin()
            : DefaultTabController(
                length: 5,
                initialIndex: chatdata.contains('notification')
                    ? 4
                    : widget.isPaymentSuccess != null
                        ? widget.isPaymentSuccess!
                            ? 0
                            : 1
                        : 1,
                child: Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      automaticallyImplyLeading: false,
                      title: TabBar(
                          labelColor: themeProvider.isDarkMode
                              ? primaryColor
                              : Colors.white,
                          indicatorColor: themeProvider.isDarkMode
                              ? primaryColor
                              : Colors.white,
                          unselectedLabelColor: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                          dividerColor: Colors.transparent,
                          isScrollable: false,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabs: const [
                            Tab(
                              icon: Icon(
                                Icons.person,
                                size: 30,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.whatshot,
                              ),
                            ),
                            Tab(icon: Icon(Icons.explore)),
                            Tab(
                              icon: Icon(
                                Icons.notifications,
                              ),
                            ),
                            Tab(
                              icon: Icon(
                                Icons.message,
                              ),
                            )
                          ]),
                    ),
                    body: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Center(
                          child: ProfilePage(
                              isPuchased: isPuchased,
                              items: items,
                              purchases: purchases),
                        ),
                        Center(
                            child: Homepage(
                          items: items,
                          isPurchased: isPuchased,
                        )),
                        Center(
                            child: ExploreMapWidget(
                          isPuchased: isPuchased,
                          currentUser: userProvider.currentUser!,
                        )),
                        const Center(child: Notifications()),
                        const Center(child: MatchScreen()),
                      ],
                    )),
              ),
      ),
    );
  }
}
