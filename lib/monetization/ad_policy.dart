/// Decides when a free player sees an interstitial.
///
/// The rule is simply "an ad before every second level": the ad shows first,
/// then the next level begins. Premium players (ads removed) never see one,
/// and there is never an ad before the very first level.
///
/// Pure and dependency-free so the cadence is unit tested on its own, with no
/// ad SDK involved.
class AdPolicy {
  const AdPolicy({this.everyLevels = 2});

  /// Show an interstitial before levels that are a multiple of this. Two means
  /// "every second level" (before levels 2, 4, 6, ...).
  final int everyLevels;

  bool shouldShowInterstitial({
    required int level,
    required bool adsRemoved,
  }) =>
      !adsRemoved && level > 1 && level % everyLevels == 0;
}
