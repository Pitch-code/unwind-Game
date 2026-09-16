import 'package:flutter_test/flutter_test.dart';
import 'package:unwind/monetization/entitlement.dart';

void main() {
  group('grantsPremium', () {
    test('a completed purchase unlocks premium', () {
      expect(grantsPremium(PurchaseOutcome.purchased), isTrue);
    });

    test('a restored entitlement unlocks premium', () {
      expect(grantsPremium(PurchaseOutcome.restored), isTrue);
    });

    test('pending does not unlock until it resolves', () {
      expect(grantsPremium(PurchaseOutcome.pending), isFalse);
    });

    test('error and cancel never unlock', () {
      expect(grantsPremium(PurchaseOutcome.error), isFalse);
      expect(grantsPremium(PurchaseOutcome.canceled), isFalse);
    });
  });

  test('premium product id is the Play Console product', () {
    expect(kPremiumProductId, 'unwind_premium');
  });
}
