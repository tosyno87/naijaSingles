// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../common/constants/constants.dart';

class NotificationData {
  static final firebaseInstance = FirebaseMessaging.instance;

  static Future<void> showCallkitIncoming({
    required String channelId,
    required String? callType,
    required String avatar,
    required String name,
    required String callTime,
    required String uuid,
  }) async {
    final params = CallKitParams(
      id: uuid,
      nameCaller: name,
      appName: 'Hookup4u2',
      avatar: avatar,
      handle: callType,
      type: callType == 'VideoCall' ? 1 : 0,
      duration: 30000,
      textAccept: "Accept".tr().toString(),
      textDecline: "Decline".tr().toString(),
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: <String, dynamic>{
        'callType': callType,
        'channelId': channelId,
        'callTime': callTime
      },
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      android: const AndroidParams(
        isCustomNotification: true,
        incomingCallNotificationChannelName: "Hookup4u",
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#FF3A5A',
        actionColor: '#4CAF50',
      ),
      ios: const IOSParams(
        configureAudioSession: false,
        iconName: 'CallKitLogo',
        handleType: 'number',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'Ringtone.caf ',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static checkcallState(channelId) async {
    bool iscalling = await firebaseFireStoreInstance
        .collection("calls")
        .doc(channelId)
        .get()
        .then((value) {
      return value.data()!["calling"] ?? false;
    });
    return iscalling;
  }
}
