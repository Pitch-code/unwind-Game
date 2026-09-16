import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_gateway.dart';

/// The real ad implementation: a Google AdMob interstitial.
///
/// During development this uses Google's **official test** interstitial unit,
/// never a real one — clicking your own live ads gets an AdMob account banned.
/// When a real account exists, only [_interstitialUnitId] changes.
///
/// It honours the [AdGateway] contract strictly: [showInterstitial] never
/// throws and never blocks. If no ad is ready it returns at once and quietly
/// starts loading the next, so a missing ad can never stall the next level.
class AdMobGateway implements AdGateway {
  AdMobGateway();

  // Google's official Android test interstitial unit id.
  static const String _interstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _ad;
  bool _loading = false;

  /// Must be called once before any ad is requested.
  Future<void> ensureInitialized() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<void> preload() async {
    if (_ad != null || _loading) return;
    _loading = true;
    await InterstitialAd.load(
      adUnitId: _interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _ad;
    if (ad == null) {
      unawaited(preload()); // nothing ready — try to have one next time
      return;
    }

    final dismissed = Completer<void>();
    void finish(InterstitialAd shown) {
      shown.dispose();
      _ad = null;
      if (!dismissed.isCompleted) dismissed.complete();
      unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (shown, error) => finish(shown),
    );

    await ad.show();
    await dismissed.future;
  }
}
