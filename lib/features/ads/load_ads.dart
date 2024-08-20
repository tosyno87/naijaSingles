import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hookup4u2/features/ads/google_ads.dart';

class LoadAds {
  static void loadInterstitialAd(
      InterstitialAd? interstitialAd, bool isInterstitialAdReady) {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              //  _moveToHome();
            },
          );

          isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (err) {
          log('Failed to load an interstitial ad: ${err.message}');
          isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void loadAds(InterstitialAd? interstitialAd) {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            // Keep a reference to the ad so you can show it later.
            interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            log('InterstitialAd failed to load: $error');
          },
        ));
  }

  final BannerAdListener listener = BannerAdListener(
    // Called when an ad is successfully received.
    onAdLoaded: (Ad ad) {
      log('Ad loaded.');
    },
    // Called when an ad request failed.
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      // Dispose the ad here to free resources.
      ad.dispose();
      log('Ad failed to load: $error');
    },
    // Called when an ad opens an overlay that covers the screen.
    onAdOpened: (Ad ad) => log('Ad opened.'),
    // Called when an ad removes an overlay that covers the screen.
    onAdClosed: (Ad ad) => log('Ad closed.'),
    // Called when an impression occurs on the ad.
    onAdImpression: (Ad ad) => log('Ad impression.'),
  );
}
