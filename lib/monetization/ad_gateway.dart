/// The game's entire view of "show me an ad", kept deliberately tiny so the
/// puzzle flow never touches the ad SDK directly.
///
/// Slice 4b provides the real Google AdMob implementation behind this
/// interface. Until then — and permanently, for premium players — the no-op
/// [NoAdsGateway] stands in, so the flow is fully exercisable without ads.
abstract interface class AdGateway {
  /// Warm up the next interstitial so showing it feels instant.
  Future<void> preload();

  /// Show an interstitial if one is ready, completing when it is dismissed.
  ///
  /// Must never throw: a missing or failed ad must never block the next
  /// level. The worst an ad failure may do is show nothing.
  Future<void> showInterstitial();
}

/// Shows nothing. Used for premium players and until real ads are wired in.
class NoAdsGateway implements AdGateway {
  const NoAdsGateway();

  @override
  Future<void> preload() async {}

  @override
  Future<void> showInterstitial() async {}
}
