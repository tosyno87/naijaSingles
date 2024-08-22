import 'dart:io';

import '../../config/app_config.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return bannerAdUnitIdAndriod;
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3215289162629879/3464472099';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return interstitialAdUnitIdAndriod;
    } else if (Platform.isIOS) {
      return "ca-app-pub-3215289162629879/2898431660";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return rewardedAdUnitIdAndriod;
    } else if (Platform.isIOS) {
      return "ca-app-pub-3215289162629879/3284873650";
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
