import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:naijasingles/features/ads/google_ads.dart';
import 'package:naijasingles/features/ads/load_ads.dart';

import '../../../common/data/repo/user_search_repo.dart';
import '../../../common/providers/user_provider.dart';
import '../../../models/user_model.dart';
class AdsManager {
  InterstitialAd? interstitialAd;
  bool isInterstitialAdReady = false;

  void load() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          log('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showIfNeeded(int count) {
    if (count % 5 == 0) {
      LoadAds.loadInterstitialAd(interstitialAd, isInterstitialAdReady);
      interstitialAd?.show();
      load();
    }
  }

  void dispose() {
    interstitialAd?.dispose();
  }
}

class HomeController {
  late final UserModel currentUser;
  int swipedCount = 0;
  List<String> likedByList = [];
  final AdsManager adsManager = AdsManager();

  Future<void> initialize(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    currentUser = userProvider.currentUser!;
    likedByList = await UserSearchRepo.getLikedByList(currentUser);
    swipedCount = await UserSearchRepo.getSwipedCount(currentUser);
    adsManager.load();
  }

  void incrementSwipe() {
    swipedCount++;
    adsManager.showIfNeeded(swipedCount);
  }

  void dispose() {
    adsManager.dispose();
  }
}
