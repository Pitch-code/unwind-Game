import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/monetization/ad_policy.dart';

void main() {
  const policy = AdPolicy();

  test('never an ad before the very first level', () {
    expect(policy.shouldShowInterstitial(level: 1, adsRemoved: false), isFalse);
  });

  test('an ad before every second level', () {
    expect(policy.shouldShowInterstitial(level: 2, adsRemoved: false), isTrue);
    expect(policy.shouldShowInterstitial(level: 3, adsRemoved: false), isFalse);
    expect(policy.shouldShowInterstitial(level: 4, adsRemoved: false), isTrue);
    expect(policy.shouldShowInterstitial(level: 10, adsRemoved: false), isTrue);
    expect(policy.shouldShowInterstitial(level: 11, adsRemoved: false), isFalse);
  });

  test('premium removes every ad', () {
    for (final level in [2, 4, 6, 100, 1000]) {
      expect(
        policy.shouldShowInterstitial(level: level, adsRemoved: true),
        isFalse,
        reason: 'premium should see no ad at level $level',
      );
    }
  });

  test('cadence is configurable', () {
    const everyThird = AdPolicy(everyLevels: 3);
    expect(everyThird.shouldShowInterstitial(level: 3, adsRemoved: false), isTrue);
    expect(everyThird.shouldShowInterstitial(level: 4, adsRemoved: false), isFalse);
    expect(everyThird.shouldShowInterstitial(level: 6, adsRemoved: false), isTrue);
  });
}
